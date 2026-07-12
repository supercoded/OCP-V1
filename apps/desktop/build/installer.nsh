; OCP-V1 NSIS installer customizations
; electron-builder will include this script automatically.

!macro customWelcomePage
  !insertMacro MUI_PAGE_WELCOME
!macroend

!macro customLicensePage
  !insertMacro MUI_PAGE_LICENSE "build/LICENSE.txt"
!macroend

!macro customInstallModePage
  ; Let user choose install scope (per-user / per-machine)
  !insertMacro MUI_PAGE_INSTFILES
!macroend

; Optional: add a custom finish page with a checkbox to launch the app.
!macro customFinishPage
  !define MUI_FINISHPAGE_RUN "$INSTDIR\OCP-V1.exe"
  !insertMacro MUI_PAGE_FINISH
!macroend
