#!/usr/bin/env bash

# connectivity_plus 7.3.1 reads NWPath.isUltraConstrained behind an availability
# check for macOS 26.0, but that symbol only exists in the macOS 26 SDK. Every
# Xcode version Flutter supports therefore fails to compile the plugin's macOS
# sources with "value of type 'NWPath' has no member 'isUltraConstrained'".
#
# LightningSend only subscribes to connectivity changes to refresh the local
# IPs, so the satellite case it reports is not used anywhere. Strip it until
# upstream ships a version that compiles against older SDKs.

set -euo pipefail

PUB_CACHE="${PUB_CACHE:-$HOME/.pub-cache}"

shopt -s nullglob
FILES=("${PUB_CACHE}"/hosted/pub.dev/connectivity_plus-*/macos/connectivity_plus/Sources/connectivity_plus/PathMonitorConnectivityProvider.swift)
shopt -u nullglob

if [ "${#FILES[@]}" -eq 0 ]; then
  echo "::error::no connectivity_plus macOS sources in ${PUB_CACHE}; run flutter pub get first"
  exit 1
fi

if sed --version >/dev/null 2>&1; then
  SED_INPLACE=(-i)
else
  SED_INPLACE=(-i '')
fi

for FILE in "${FILES[@]}"; do
  if grep -q 'isUltraConstrained' "${FILE}"; then
    # Drop the whole availability block, including its closing brace.
    sed "${SED_INPLACE[@]}" \
      '/#available(macOS 26.0, \*), path.isUltraConstrained {/,/^      }$/d' \
      "${FILE}"
    if grep -q 'isUltraConstrained' "${FILE}"; then
      echo "::error::could not remove the isUltraConstrained block from ${FILE}"
      exit 1
    fi
    echo "patched ${FILE}"
  else
    echo "nothing to do, ${FILE} no longer references isUltraConstrained"
  fi
done
