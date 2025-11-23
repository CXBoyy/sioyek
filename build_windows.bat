@echo off
setlocal

REM === Configure output folder here ===
REM Change this to whatever path you want:
set "OUTNAME=sioyek-release-windows"
set "SCRIPT_DIR=%~dp0"

set "OUTDIR=%SCRIPT_DIR%..\build\%OUTNAME%"

cd mupdf\platform\win32\
msbuild mupdf.sln /property:Configuration=Debug 
REM msbuild mupdf.sln /property:Configuration=Release
cd ..\..\..

cd zlib
nmake -f win32/makefile.msc
cd ..

if /I "%~1"=="portable" (
    qmake -tp vc pdf_viewer_build_config.pro
) else (
    qmake -tp vc "DEFINES+=NON_PORTABLE" pdf_viewer_build_config.pro
)

msbuild -maxcpucount sioyek.vcxproj /property:Configuration=Debug /property:Platform=x64
@REM msbuild -maxcpucount sioyek.vcxproj /property:Configuration=Release

REM Recreate output directory
rmdir /S /Q "%OUTDIR%" 2>NUL
mkdir "%OUTDIR%" 2>NUL

REM Copy build artifacts
copy /Y release\sioyek.exe "%OUTDIR%\sioyek.exe"
copy /Y pdf_viewer\keys.config "%OUTDIR%\keys.config"
copy /Y pdf_viewer\prefs.config "%OUTDIR%\prefs.config"
xcopy /E /I /Y pdf_viewer\shaders "%OUTDIR%\shaders\"
copy /Y tutorial.pdf "%OUTDIR%\tutorial.pdf"
windeployqt "%OUTDIR%\sioyek.exe"
copy /Y windows_runtime\vcruntime140_1.dll "%OUTDIR%\vcruntime140_1.dll"
copy /Y windows_runtime\libssl-1_1-x64.dll "%OUTDIR%\libssl-1_1-x64.dll"
copy /Y windows_runtime\libcrypto-1_1-x64.dll "%OUTDIR%\libcrypto-1_1-x64.dll"

if /I "%~1"=="portable" (
    copy /Y pdf_viewer\keys_user.config "%OUTDIR%\keys_user.config"
    copy /Y pdf_viewer\prefs_user.config "%OUTDIR%\prefs_user.config"
    7z a "%OUTNAME%-portable.zip" "%OUTDIR%"
) else (
    7z a "%OUTNAME%.zip" "%OUTDIR%"
)

endlocal
