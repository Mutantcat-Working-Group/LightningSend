; LightingSend NSIS installer.
; Payload/output directories and version are overridable from CI via /DVERSION=... /DPayloadDir=... /DResultDir=...
; Copy the contents of the Release folder plus app/assets/packaging/logo.ico into PayloadDir first.

Unicode true
SetCompressor /SOLID lzma

!include "MUI2.nsh"

!ifndef VERSION
  !define VERSION "1.0.20260920"
!endif
!ifndef VI_VERSION
  ; Windows version resources require four numeric parts, each <= 65535.
  ; 1.0.YYYYMMDD is encoded as 1.0.YYYY.MMDD (leading zero stripped).
  !define VI_VERSION "1.0.2026.920"
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

!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_COMPONENTS
!insertmacro MUI_PAGE_INSTFILES
!define MUI_FINISHPAGE_RUN "$INSTDIR\lightingsend_app.exe"
!define MUI_FINISHPAGE_RUN_TEXT "Run LightingSend"
!insertmacro MUI_PAGE_FINISH

!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES

!insertmacro MUI_LANGUAGE "English"
!insertmacro MUI_LANGUAGE "SimpChinese"

Section "LightingSend (required)" SEC_APP
  SectionIn RO
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

Section "Desktop shortcut" SEC_DESKTOP
  CreateShortcut "$DESKTOP\LightingSend.lnk" "$INSTDIR\lightingsend_app.exe"
SectionEnd

Section "Start menu shortcuts" SEC_STARTMENU
  CreateDirectory "$SMPROGRAMS\LightingSend"
  CreateShortcut "$SMPROGRAMS\LightingSend\LightingSend.lnk" "$INSTDIR\lightingsend_app.exe"
  CreateShortcut "$SMPROGRAMS\LightingSend\Uninstall LightingSend.lnk" "$INSTDIR\Uninstall-LightingSend.exe"
SectionEnd

!insertmacro MUI_FUNCTION_DESCRIPTION_BEGIN
  !insertmacro MUI_DESCRIPTION_TEXT ${SEC_APP} "Installs the LightingSend application."
  !insertmacro MUI_DESCRIPTION_TEXT ${SEC_DESKTOP} "Adds a LightingSend shortcut to your desktop."
  !insertmacro MUI_DESCRIPTION_TEXT ${SEC_STARTMENU} "Adds LightingSend shortcuts to the Start Menu."
!insertmacro MUI_FUNCTION_DESCRIPTION_END

Section "Uninstall"
  nsExec::ExecToLog 'powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Get-AppxPackage org.mutantcat.lightingsend | Remove-AppxPackage"'

  Delete "$DESKTOP\LightingSend.lnk"
  Delete "$SMPROGRAMS\LightingSend\LightingSend.lnk"
  Delete "$SMPROGRAMS\LightingSend\Uninstall LightingSend.lnk"
  RMDir "$SMPROGRAMS\LightingSend"

  DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\LightingSend"
  DeleteRegKey HKLM "Software\LightingSend"
  RMDir /r "$INSTDIR"
SectionEnd
