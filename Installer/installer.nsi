# This files contains the NSIS script for building the installer for the Beeftext application
# Xavier Michelon
# 2017-11-12

!include "MUI2.nsh" # use the MUI2 scripts for better visual aspect
!include "LogicLib.nsh" # we use the logic lib for easy conditional statements
!include "nsDialogs.nsh" # used for custom dialog pages
!include "FileFunc.nsh" # file functions (used for GetSize)


#global defines ( basically compile time constants)
!define APP_FANCY_NAME "Beeftext"
!define APP_NAME "Beeftext"
!define EXE_SRC_DIR ..\_build\Win32\Release
!define UNINSTALLER_FILE_NAME Uninstall.exe
!define REGISTRY_UNINSTALLER_FOLDER Software\Microsoft\Windows\CurrentVersion\Uninstall
!define OUTPUT_DIR _build
!define RESOURCES_FOLDER_PATH "..\Resources"
!define VS_DEVENV_PATH "C:\Program Files (x86)\Microsoft Visual Studio\2017\Community\Common7\IDE\devenv.com"
!define VC_REDIST_RUNTIME_FILE "VC_redist.x86.exe"
!define VC_REDIST_RUNTIME_FILE_PATH "${RESOURCES_FOLDER_PATH}\Vendor\VCRuntime\${VC_REDIST_RUNTIME_FILE}"
!define LICENSE_FILE_NAME "LICENSE"
!define LICENSE_FILE_PATH "..\${LICENSE_FILE_NAME}"
!define WEBSITE "https://beeftext.org"
!define AUTHOR "Xavier Michelon"
!define COMPANY "beeftext.org"
!define VERSION_MAJOR 0
!define VERSION_MINOR 1
!define APP_VERSION "${VERSION_MAJOR}.${VERSION_MINOR}"
!define LEFT_IMAGE_PATH "${RESOURCES_FOLDER_PATH}\installerLeftImage.bmp"
!define TOP_IMAGE_PATH "${RESOURCES_FOLDER_PATH}\installerTopImage.bmp"
!define APP_DATA_REGISTRY_KEY "Software\${COMPANY}\${APP_NAME}"

# Settings for the Modern UI 2 NSIS plugin
!define MUI_WELCOMEFINISHPAGE_BITMAP ${LEFT_IMAGE_PATH}
!define MUI_UNWELCOMEFINISHPAGE_BITMAP ${LEFT_IMAGE_PATH}
!define MUI_HEADERIMAGE
!define MUI_HEADERIMAGE_RIGHT
!define MUI_HEADERIMAGE_BITMAP ${TOP_IMAGE_PATH}
!define MUI_HEADERIMAGE_UNBITMAP ${TOP_IMAGE_PATH}
#!define MUI_FINISHPAGE_NOAUTOCLOSE
!define MUI_FINISHPAGE_RUN "$INSTDIR\${APP_NAME}.exe"
#!define MUI_UNFINISHPAGE_NOAUTOCLOSE

# Build the solution file and stop if the result is not 0
!system '"${VS_DEVENV_PATH}" "..\${APP_NAME}.sln" /rebuild "Release|x86"' = 0


# General attributes for the installer/uninstaller
Name  "${APP_FANCY_NAME} v${VERSION_MAJOR}.${VERSION_MINOR}"
!system "mkdir ${OUTPUT_DIR}" # create the directory where the installer file will be created, if it does not exist yet
OutFile "${OUTPUT_DIR}\${APP_NAME}Installer.exe"
SetCompressor lzma # better result than default zlib, but slower
RequestExecutionLevel none
InstallDir "$PROGRAMFILES32\${APP_FANCY_NAME}"


#define the sequence of pages for the installer
!insertmacro MUI_PAGE_WELCOME
!define MUI_TEXT_LICENSE_TITLE "License"
!define MUI_TEXT_LICENSE_SUBTITLE "Please review the licensing terms before installing $(^NameDA)."
!define MUI_INNERTEXT_LICENSE_TOP "Press Page Down to see the rest of the terms and conditions."
!define MUI_INNERTEXT_LICENSE_BOTTOM "If you accept the terms of the license agreement, click I Agree to continue. You must accept the licensing terms to install $(^NameDA)."
!insertmacro MUI_PAGE_LICENSE "${LICENSE_FILE_PATH}"
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH


#define the sequence of pages for the uninstaller
!insertmacro MUI_UNPAGE_WELCOME
!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES
!insertmacro MUI_UNPAGE_FINISH


# Installer in english only. These call are not necessary but removes a lot of warning from the compiler output
!insertmacro MUI_LANGUAGE "English"
!insertmacro MUI_RESERVEFILE_LANGDLL


###################################
# Installer initialization function
###################################
Function .onInit
  !insertmacro MUI_LANGDLL_DISPLAY
  Call checkAlreadyInstalled
FunctionEnd


###################################################
# install the VC Redistributable Runtime for VS2013
###################################################
Function InstallVCRedistributableRuntime
   SetOutPath $TEMP
   ${Unless} ${FileExists} "$TEMP\${VC_REDIST_RUNTIME_FILE}"         
       DetailPrint "Installing VC++ 2015 Redistributable Runtime"         
       File ${VC_REDIST_RUNTIME_FILE_PATH}
       ExecWait "$TEMP\${VC_REDIST_RUNTIME_FILE} /q"         
       DetailPrint "Cleaning up"         
       Delete $TEMP\${VC_REDIST_RUNTIME_FILE}     
   ${EndUnless}
FunctionEnd


###############################################
# Check if the application is already installed
###############################################
Function checkAlreadyInstalled
  Push $0 
  ReadRegStr $0 HKLM "${REGISTRY_UNINSTALLER_FOLDER}\${APP_NAME}" "UninstallString"
  ${If} $0 != ""
    MessageBox MB_YESNO|MB_ICONQUESTION "Before you can install ${APP_FANCY_NAME}, you must uninstall the version that is currently installed on your computer.$\n$\nDo you want to uninstall the previous version of ${APP_FANCY_NAME} ?" /SD IDNO IDYES yes IDNO no
no:
    Abort
yes:
    ExecWait '"$INSTDIR\${UNINSTALLER_FILE_NAME}" _?=$INSTDIR' # the _?=$INSTDIR means that the uninstaller will not copy itself but run from the installer folder, forcing ExecWait to actually wait for the uninstaller to finish.
  ${Endif}
  Pop $0
FunctionEnd


#########################################################################
# Retrieve the installation folder size - in kB - and put it on the stack 
# Do not call before all files are installed
#########################################################################
Function getInstallDirSize
  Push $0
  Push $1
  Push $2
  ${GetSize} "$INSTDIR" "/S=0K /G=1" $0 $1 $2 # File the size in MB of the Install dir, including subdirs
  Pop $2
  Pop $1
  Exch $0 # Exchange the value of $0 and the top of the Stack
FunctionEnd


# Definitions of the different installation types
InstType "Default" #1


#################
# Default Section
#################
Section "${APP_NAME}" secApp

SectionIn RO # This section is mandatory
SetShellVarContext all

call InstallVCRedistributableRuntime

setOutPath $INSTDIR
# copy file
file "${EXE_SRC_DIR}\${APP_NAME}.exe"
file "$%QTDIR%\bin\Qt5Core.dll"
file "$%QTDIR%\bin\Qt5Gui.dll"
file "$%QTDIR%\bin\Qt5Widgets.dll"
setOutPath $INSTDIR\platforms
file "$%QTDIR%\plugins\platforms\qwindows.dll"
setOutPath $INSTDIR\imageformats
file "$%QTDIR%\plugins\imageformats\qico.dll"

# Create uninstall
WriteUninstaller "${UNINSTALLER_FILE_NAME}"

# Add Windows registry keys for uninstaller
WriteRegStr HKLM "${REGISTRY_UNINSTALLER_FOLDER}\${APP_NAME}" "DisplayName" "${APP_FANCY_NAME}"
WriteRegStr HKLM "${REGISTRY_UNINSTALLER_FOLDER}\${APP_NAME}" "UninstallString" '"$INSTDIR\${UNINSTALLER_FILE_NAME}"'
WriteRegStr HKLM "${REGISTRY_UNINSTALLER_FOLDER}\${APP_NAME}" "InstallLocation" "$INSTDIR"
WriteRegStr HKLM "${REGISTRY_UNINSTALLER_FOLDER}\${APP_NAME}" "DisplayIcon" "$INSTDIR\${APP_NAME}.exe"
WriteRegStr HKLM "${REGISTRY_UNINSTALLER_FOLDER}\${APP_NAME}" "Publisher" "${COMPANY}"
WriteRegStr HKLM "${REGISTRY_UNINSTALLER_FOLDER}\${APP_NAME}" "RegOwner" "${AUTHOR}"
WriteRegStr HKLM "${REGISTRY_UNINSTALLER_FOLDER}\${APP_NAME}" "RegCompany" "${COMPANY}"
WriteRegStr HKLM "${REGISTRY_UNINSTALLER_FOLDER}\${APP_NAME}" "URLUpdateInfo" "${WEBSITE}"
WriteRegStr HKLM "${REGISTRY_UNINSTALLER_FOLDER}\${APP_NAME}" "URLInfoAbout" "${WEBSITE}"
WriteRegStr HKLM "${REGISTRY_UNINSTALLER_FOLDER}\${APP_NAME}" "DisplayVersion" "${APP_VERSION}"
WriteRegDWORD HKLM "${REGISTRY_UNINSTALLER_FOLDER}\${APP_NAME}" "VersionMajor" "${VERSION_MAJOR}"
WriteRegDWORD HKLM "${REGISTRY_UNINSTALLER_FOLDER}\${APP_NAME}" "VersionMinor" "${VERSION_MINOR}"
WriteRegDWORD HKLM "${REGISTRY_UNINSTALLER_FOLDER}\${APP_NAME}" "NoModify" 1
WriteRegDWORD HKLM "${REGISTRY_UNINSTALLER_FOLDER}\${APP_NAME}" "NoRepair" 1
Call getInstallDirSize
Pop $0
WriteRegDWORD HKLM "${REGISTRY_UNINSTALLER_FOLDER}\${APP_NAME}" "EstimatedSize" $0

SectionEnd


#############################
# Start menu shortcut section
#############################
Section "Start Menu Shortcuts" secStartMenuShortcuts

SectionIn 1 # This section is enabled for the Full and Default installation types
SetShellVarContext all # The shortcut in the start menu wil be created for all users

CreateDirectory "$SMPROGRAMS\${APP_FANCY_NAME}"
CreateShortCut "$SMPROGRAMS\${APP_FANCY_NAME}\${APP_FANCY_NAME}.lnk" "$INSTDIR\${APP_NAME}.exe" "" "$INSTDIR\${APP_NAME}.exe" 0
CreateShortCut "$SMPROGRAMS\${APP_FANCY_NAME}\Uninstall ${APP_FANCY_NAME}.lnk" "$INSTDIR\${UNINSTALLER_FILE_NAME}" "" "$INSTDIR\${UNINSTALLER_FILE_NAME}" 0

SectionEnd


##########################
# Desktop shortcut section
##########################
Section "Desktop Shortcut" secDesktopShortcut

SectionIn 1 # This section is enabled for the Full installation type only
SetShellVarContext current # The shortcut will be created for the current user only

CreateShortCut "$DESKTOP\${APP_FANCY_NAME}.lnk" "$INSTDIR\${APP_NAME}.exe" "" "$INSTDIR\${APP_NAME}.exe" 0

SectionEnd


#####################################
# Uninstaller
#####################################

Section "Uninstall"

# Remove application files and folders
SetShellVarContext all
Delete "$INSTDIR\*.exe"
Delete "$INSTDIR\*.dll"
Delete "$INSTDIR\platforms\*.dll"
RMDir  "$INSTDIR\platforms"
Delete "$INSTDIR\imageformats\*.dll"
RMDir  "$INSTDIR\imageformats"
Delete "$INSTDIR\${UNINSTALLER_FILE_NAME}"
RMDir  "$INSTDIR"

# Remove registry keys that are used for the uninstaller
DeleteRegKey HKLM "${REGISTRY_UNINSTALLER_FOLDER}\${APP_NAME}"

# Remove Start menu entries, if any
Delete "$SMPROGRAMS\${APP_fANCY_NAME}\*.*"
RMDir "$SMPROGRAMS\${APP_FANCY_NAME}"

# Remove Desktop shortcut, if any
SetShellVarContext current
Delete "$DESKTOP\${APP_FANCY_NAME}.lnk"

SectionEnd