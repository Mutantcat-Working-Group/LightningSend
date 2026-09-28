; LightingSend NSIS installer.
; Payload/output directories and version are overridable from CI via /DVERSION=... /DPayloadDir=... /DResultDir=...
; Copy the contents of the Release folder plus app/assets/packaging/logo.ico into PayloadDir first.

Unicode true
SetCompressor /SOLID lzma

!include "MUI2.nsh"

!ifndef VERSION
  !define VERSION "1.0.20260923"
!endif
!ifndef VI_VERSION
  ; Windows version resources require four numeric parts, each <= 65535.
  ; 1.0.YYYYMMDD is encoded as 1.0.YYYY.MMDD (leading zero stripped).
  !define VI_VERSION "1.0.2026.923"
!endif
!ifndef PayloadDir
  !define PayloadDir "D:\nsis"
!endif
!ifndef ResultDir
  !define ResultDir "D:\nsis-result"
!endif

Name "LightingSend"
Caption "LightingSend ${VERSION} Setup"
OutFile "${ResultDir}\LightingSend-Setup.exe"
InstallDir "$PROGRAMFILES64\LightingSend"
InstallDirRegKey HKLM "Software\LightingSend" "InstallDir"
RequestExecutionLevel admin
ShowInstDetails show
ShowUnInstDetails show
Icon "${PayloadDir}\logo.ico"
UninstallIcon "${PayloadDir}\logo.ico"

VIProductVersion "${VI_VERSION}"
VIAddVersionKey "ProductName" "LightingSend"
VIAddVersionKey "ProductVersion" "${VERSION}"
VIAddVersionKey "FileVersion" "${VERSION}"
VIAddVersionKey "FileDescription" "LightingSend Installer"
VIAddVersionKey "LegalCopyright" "Copyright (C) 2026 Mutantcat Working Group"
VIAddVersionKey "OriginalFilename" "LightingSend-Setup.exe"

; Name the product in the footer where NSIS would otherwise show its own toolkit.
BrandingText "LightingSend v${VERSION} - Mutantcat Working Group"

!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_COMPONENTS
!insertmacro MUI_PAGE_INSTFILES
!define MUI_FINISHPAGE_RUN "$INSTDIR\lightingsend_app.exe"
!define MUI_FINISHPAGE_RUN_TEXT "$(FINISH_RUN_LIGHTINGSEND)"
!insertmacro MUI_PAGE_FINISH

!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES

; SimpChinese leads so a fresh install opens in Chinese; English stays selectable.
!insertmacro MUI_LANGUAGE "SimpChinese"
!insertmacro MUI_LANGUAGE "English"

; The toolkit translates its own pages, but everything this script names itself
; has to carry both languages of its own.
LangString FINISH_RUN_LIGHTINGSEND ${LANG_SIMPCHINESE} "运行 LightingSend"
LangString FINISH_RUN_LIGHTINGSEND ${LANG_ENGLISH} "Run LightingSend"
LangString SEC_APP ${LANG_SIMPCHINESE} "LightingSend（必需）"
LangString SEC_APP ${LANG_ENGLISH} "LightingSend (required)"
LangString SEC_DESKTOP ${LANG_SIMPCHINESE} "桌面快捷方式"
LangString SEC_DESKTOP ${LANG_ENGLISH} "Desktop shortcut"
LangString SEC_STARTMENU ${LANG_SIMPCHINESE} "开始菜单快捷方式"
LangString SEC_STARTMENU ${LANG_ENGLISH} "Start menu shortcuts"
LangString DESC_SEC_APP ${LANG_SIMPCHINESE} "安装 LightingSend 应用程序。"
LangString DESC_SEC_APP ${LANG_ENGLISH} "Installs the LightingSend application."
LangString DESC_SEC_DESKTOP ${LANG_SIMPCHINESE} "在桌面上添加 LightingSend 快捷方式。"
LangString DESC_SEC_DESKTOP ${LANG_ENGLISH} "Adds a LightningSend shortcut to your desktop."
LangString DESC_SEC_STARTMENU ${LANG_SIMPCHINESE} "在开始菜单中添加 LightingSend 快捷方式。"
LangString DESC_SEC_STARTMENU ${LANG_ENGLISH} "Adds LightingSend shortcuts to the Start Menu."

Section "$(SEC_APP)" SEC_APP
  SectionIn RO
  SetShellVarContext all
  SetOutPath "$INSTDIR"
  File "${PayloadDir}\lightingsend_app.exe"
  File "${PayloadDir}\*.dll"
  File /r "${PayloadDir}\data\*.*"
  File "${PayloadDir}\lightingsend_app.exe.manifest"
  File "${PayloadDir}\lightingsend_msix_helper.msix"

  nsExec::ExecToLog 'powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Add-AppxPackage -Path \"$INSTDIR\lightingsend_msix_helper.msix\" -ExternalLocation \"$INSTDIR\""'

  WriteUninstaller "$INSTDIR\Uninstall-LightingSend.exe"

  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\LightingSend" "DisplayName" "LightingSend"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\LightingSend" "DisplayVersion" "${VERSION}"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\LightingSend" "Publisher" "Mutantcat Working Group"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\LightingSend" "DisplayIcon" "$INSTDIR\lightingsend_app.exe"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\LightingSend" "UninstallString" '"$INSTDIR\Uninstall-LightingSend.exe"'
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\LightingSend" "InstallLocation" "$INSTDIR"
  WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\LightingSend" "NoModify" 1
  WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\LightingSend" "NoRepair" 1
  WriteRegStr HKLM "Software\LightingSend" "InstallDir" "$INSTDIR"
SectionEnd

Section "$(SEC_DESKTOP)" SEC_DESKTOP
  SetShellVarContext all
  CreateShortcut "$DESKTOP\LightingSend.lnk" "$INSTDIR\lightingsend_app.exe"
SectionEnd

Section "$(SEC_STARTMENU)" SEC_STARTMENU
  SetShellVarContext all
  CreateDirectory "$SMPROGRAMS\LightingSend"
  CreateShortcut "$SMPROGRAMS\LightingSend\LightingSend.lnk" "$INSTDIR\lightingsend_app.exe"
  CreateShortcut "$SMPROGRAMS\LightingSend\Uninstall LightingSend.lnk" "$INSTDIR\Uninstall-LightingSend.exe"
SectionEnd

!insertmacro MUI_FUNCTION_DESCRIPTION_BEGIN
  !insertmacro MUI_DESCRIPTION_TEXT ${SEC_APP} "$(DESC_SEC_APP)"
  !insertmacro MUI_DESCRIPTION_TEXT ${SEC_DESKTOP} "$(DESC_SEC_DESKTOP)"
  !insertmacro MUI_DESCRIPTION_TEXT ${SEC_STARTMENU} "$(DESC_SEC_STARTMENU)"
!insertmacro MUI_FUNCTION_DESCRIPTION_END

Section "Uninstall"
  SetShellVarContext all
  nsExec::ExecToLog 'powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Get-AppxPackage org.mutantcat.lightingsend | Remove-AppxPackage"'

  Delete "$DESKTOP\LightingSend.lnk"
  Delete "$SMPROGRAMS\LightingSend\LightingSend.lnk"
  Delete "$SMPROGRAMS\LightingSend\Uninstall LightingSend.lnk"
  RMDir "$SMPROGRAMS\LightingSend"

  DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\LightingSend"
  DeleteRegKey HKLM "Software\LightingSend"
  RMDir /r "$INSTDIR"
SectionEnd
