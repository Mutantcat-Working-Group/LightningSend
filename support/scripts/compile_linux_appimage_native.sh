#!/usr/bin/env bash

# Builds a LightingSend AppImage from a Flutter Linux bundle, without Docker.
#
# The upstream recipe (support/build/appimage/AppImageBuilder_*.yml) drives
# appimage-builder inside its Docker image, which only exists for amd64 and
# therefore cannot run on the arm64 runners. This script performs the same
# steps natively and for the architecture of the machine it runs on:
#
#   1. stage the Flutter bundle, the desktop entry, the icons and an AppRun
#   2. bundle the distro packages the recipe's apt section relies on
#   3. package the AppDir with the architecture specific appimagetool
#
# The package list is the dependency closure of appimage-builder's `include`
# entries minus its default exclude list (see appimagebuilder/modules/deploy/
# apt/listings.py), so the result matches what appimage-builder produces: the
# graphics stack is left to the host system to keep proprietary drivers
# working, while GTK and the appindicator of the tray plugin are bundled.
#
# Usage: support/scripts/compile_linux_appimage_native.sh <bundle-dir> [output-dir]
#
# Requirements: bash, awk/grep/sed, curl, apt, dpkg-deb and the Flutter build
# dependencies of the workflow that produced <bundle-dir>.

set -euo pipefail

BUNDLE_DIR="${1:?usage: compile_linux_appimage_native.sh <bundle-dir> [output-dir]}"
OUTPUT_DIR="${2:-.}"

APP_ID="org.mutantcat.lightingsend"
APP_NAME="LightingSend"
APP_EXEC="lightingsend_app"
APP_ICON="lightingsend"

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

DEB_ARCH="$(dpkg --print-architecture)"
case "${DEB_ARCH}" in
  amd64) DEB_TRIPLET="x86_64-linux-gnu"; APPIMAGETOOL_ARCH="x86_64"; ARCH_NAME="x86-64" ;;
  arm64) DEB_TRIPLET="aarch64-linux-gnu"; APPIMAGETOOL_ARCH="aarch64"; ARCH_NAME="arm-64" ;;
  *) echo "unsupported dpkg architecture: ${DEB_ARCH}" >&2; exit 1 ;;
esac

VERSION="$(sed -n 's/^version: \([0-9]*\.[0-9]*\.[0-9]*\).*/\1/p' "${REPO_ROOT}/app/pubspec.yaml")"
if [ -z "${VERSION}" ]; then
  echo "could not read the version from app/pubspec.yaml" >&2
  exit 1
fi

if [ ! -x "${BUNDLE_DIR}/${APP_EXEC}" ]; then
  echo "no ${APP_EXEC} binary found in ${BUNDLE_DIR}" >&2
  exit 1
fi

WORK_DIR="$(mktemp -d)"
trap 'rm -rf "${WORK_DIR}"' EXIT

APPDIR="${OUTPUT_DIR%/}/AppDir"
mkdir -p "${APPDIR}"

# --- stage the Flutter bundle -------------------------------------------------
cp -a "${BUNDLE_DIR}/." "${APPDIR}/"

# --- icons and desktop entry --------------------------------------------------
for SIZE in 32 128 256; do
  mkdir -p "${APPDIR}/usr/share/icons/hicolor/${SIZE}x${SIZE}/apps"
  cp "${REPO_ROOT}/app/assets/img/logo-${SIZE}.png" \
    "${APPDIR}/usr/share/icons/hicolor/${SIZE}x${SIZE}/apps/${APP_ICON}.png"
done
cp "${REPO_ROOT}/app/assets/img/logo-256.png" "${APPDIR}/${APP_ICON}.png"
ln -sfn "${APP_ICON}.png" "${APPDIR}/.DirIcon"

cat > "${APPDIR}/${APP_ID}.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=${APP_NAME}
Exec=${APP_EXEC}
Icon=${APP_ICON}
Terminal=false
Categories=Utility;
EOF

# --- launcher -----------------------------------------------------------------
# Unlike the default AppRun this also covers the distro packages bundled below
# and points the GTK stack at the modules, loaders and schemas in the AppDir.
cat > "${APPDIR}/AppRun" <<'APPRUN'
#!/bin/sh
APPDIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"

APP_LIBRARY_PATH=""
for DIR in \
  "$APPDIR/lib" \
  "$APPDIR/lib/__DEB_TRIPLET__" \
  "$APPDIR/usr/lib" \
  "$APPDIR/usr/lib/__DEB_TRIPLET__"; do
  [ -d "$DIR" ] || continue
  APP_LIBRARY_PATH="${APP_LIBRARY_PATH:+$APP_LIBRARY_PATH:}$DIR"
done
export LD_LIBRARY_PATH="${LD_LIBRARY_PATH:+$LD_LIBRARY_PATH:}${APP_LIBRARY_PATH}"

export XDG_DATA_DIRS="$APPDIR/usr/share:/usr/local/share:/usr/share${XDG_DATA_DIRS:+:$XDG_DATA_DIRS}"
export XDG_CONFIG_DIRS="$APPDIR/etc/xdg:$XDG_CONFIG_DIRS"
export PATH="$APPDIR/usr/bin:$PATH"

PIXBUF_LOADERS="$APPDIR/usr/lib/__DEB_TRIPLET__/gdk-pixbuf-2.0/2.10.0/loaders"
if [ -d "$PIXBUF_LOADERS" ]; then
  export GDK_PIXBUF_MODULEDIR="$PIXBUF_LOADERS"
  export GDK_PIXBUF_MODULE_FILE="$PIXBUF_LOADERS/loaders.cache"
fi
[ -d "$APPDIR/usr/lib/__DEB_TRIPLET__/gio/modules" ] && \
  export GIO_MODULE_DIR="$APPDIR/usr/lib/__DEB_TRIPLET__/gio/modules"
[ -d "$APPDIR/usr/share/glib-2.0/schemas" ] && \
  export GSETTINGS_SCHEMA_DIR="$APPDIR/usr/share/glib-2.0/schemas"
[ -d "$APPDIR/usr/lib/__DEB_TRIPLET__/gtk-3.0" ] && \
  export GTK_PATH="$APPDIR/usr/lib/__DEB_TRIPLET__/gtk-3.0"
export GTK_EXE_PREFIX="$APPDIR/usr"
export GTK_DATA_PREFIX="$APPDIR/usr"

exec "$APPDIR/__APP_EXEC__" "$@"
APPRUN
sed -e "s|__DEB_TRIPLET__|${DEB_TRIPLET}|g" -e "s|__APP_EXEC__|${APP_EXEC}|g" \
  "${APPDIR}/AppRun" > "${APPDIR}/AppRun.tmp"
mv "${APPDIR}/AppRun.tmp" "${APPDIR}/AppRun"
chmod +x "${APPDIR}/AppRun"

# --- bundle the distro dependencies -------------------------------------------
# Equivalent of the apt section of the recipe, which only lists these two
# packages and lets the resolver pull in everything they need.
APT_PACKAGES=(libayatana-appindicator3-1 librsvg2-common)

# appimage-builder's default exclude list, including the graphics stack and the
# base system libraries.
APT_EXCLUDE=(
  dpkg debconf apt
  adduser avahi-daemon base-files bind9-host consolekit coreutils dbus
  debianutils fdisk init-system-helpers iso-codes libcap2-bin libinput-bin
  libpam-modules-bin libpam-runtime lsb-base mount multiarch-support passwd
  shared-mime-info systemd systemd-sysv sysvinit-utils ucf util-linux
  xdg-user-dirs
  fontconfig fontconfig-config
  libdrm* libegl-* libegl1* libegl1-* libgbm* libgl1* libglapi* libgles*
  libglvnd* libglx* mesa-* libx11-* libxcb-dri2-0 libxcb-dri3-0 libxcb-glx0
  libxcb-present0 libxcb-render0 libxcb-shape0 libxcb-shm0 libxcb-xfixes0
  libxcb1 x11-common libwayland-*
  libc6 zlib1g libstdc++6
)

DEPENDENCIES="$(
  apt-cache depends --recurse --no-recommends --no-suggests --no-conflicts \
    --no-breaks --no-replaces --no-enhances "${APT_PACKAGES[@]}" |
    grep -E '^[a-z0-9]' | sort -u
)"

PACKAGES=()
while IFS= read -r PACKAGE; do
  [ -n "${PACKAGE}" ] || continue
  # apt-cache also reports virtual packages, which cannot be downloaded
  apt-cache show "${PACKAGE}" > /dev/null 2>&1 || continue
  EXCLUDED=false
  for PATTERN in "${APT_EXCLUDE[@]}"; do
    # shellcheck disable=SC2053  # the entries above are meant to be globs
    if [[ "${PACKAGE}" == ${PATTERN} ]]; then
      EXCLUDED=true
      break
    fi
  done
  if [ "${EXCLUDED}" = false ]; then
    PACKAGES+=("${PACKAGE}")
  fi
done <<< "${DEPENDENCIES}"

if [ "${#PACKAGES[@]}" -eq 0 ]; then
  echo "no distro packages to bundle" >&2
  exit 1
fi
echo "bundling ${#PACKAGES[@]} distro packages"

DEB_DIR="${WORK_DIR}/debs"
mkdir -p "${DEB_DIR}"
(
  cd "${DEB_DIR}"
  apt-get download "${PACKAGES[@]}"
)
for DEB in "${DEB_DIR}"/*.deb; do
  dpkg-deb -x "${DEB}" "${APPDIR}"
done

# --- package the AppImage ------------------------------------------------------
APPIMAGETOOL="${WORK_DIR}/appimagetool-${APPIMAGETOOL_ARCH}.AppImage"
curl -fsSL --retry 3 \
  -o "${APPIMAGETOOL}" \
  "https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-${APPIMAGETOOL_ARCH}.AppImage"
chmod +x "${APPIMAGETOOL}"

APPIMAGE="${OUTPUT_DIR%/}/LightingSend-${VERSION}-linux-${ARCH_NAME}.AppImage"
# appimagetool is a type 2 AppImage itself and mounting it requires FUSE, which
# is not available on the runners; this environment variable makes the runtime
# unpack and run it instead.
APPIMAGE_EXTRACT_AND_RUN=1 "${APPIMAGETOOL}" --no-appstream "${APPDIR}" "${APPIMAGE}"

echo "built ${APPIMAGE}"
