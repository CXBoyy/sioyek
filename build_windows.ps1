param(
    # First argument, e.g. "portable"
    [string]$Mode
)

$ErrorActionPreference = "SilentlyContinue"

$OUTNAME   = "sioyek-release-windows"
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# Make relative paths behave like the .bat (run from script directory)
Set-Location $scriptDir

# One level up from script dir, then build\OUTNAME
$outRoot = Join-Path $scriptDir "..\build"
# $OUTDIR  = Join-Path $outRoot $OUTNAME
$OUTDIR = Join-Path $scriptDir $OUTNAME

# Log file lives next to the script during the build
$ts = Get-Date -Format "yyyy-MM-dd_HH-mm"
$globalLog = Join-Path $scriptDir "build_$ts.log"
if (Test-Path $globalLog) {
    Remove-Item $globalLog -Force
}

# Run the whole build; stream to console AND append to log file
& {
    Write-Host "Script directory : $scriptDir"
    Write-Host "Output directory : $OUTDIR"
    Write-Host "Mode             : $Mode"
    Write-Host ""

    # === MuPDF ===
    Set-Location "mupdf\platform\win32"
    & msbuild "mupdf.sln" "/property:Configuration=Debug" "/property:Platform=x64"
    & msbuild "mupdf.sln" "/property:Configuration=Release" "/property:Platform=x64"
    Set-Location $scriptDir

    # === zlib ===
    Set-Location "zlib"
    & nmake "-f" "win32/makefile.msc"
    Set-Location $scriptDir

    # === qmake config depending on 'portable' flag ===
    if ($Mode -and $Mode.ToLower() -eq "portable") {
        & qmake "-tp" "vc" "CONFIG+=debug" "pdf_viewer_build_config.pro"
    }
    else {
        & qmake "-tp" "vc" "DEFINES+=NON_PORTABLE" "pdf_viewer_build_config.pro"
    }

    # === main build (Debug/x64) ===
    & msbuild "-maxcpucount" "sioyek.vcxproj" "/property:Configuration=Debug" "/property:Platform=x64"
    & msbuild "-maxcpucount" "sioyek.vcxproj" "/property:Configuration=Release" "/property:Platform=x64"

    # === Recreate output directory (same behavior as your .bat) ===
    if (Test-Path $OUTDIR) {
        Remove-Item $OUTDIR -Recurse -Force
    }
    New-Item -ItemType Directory -Path $OUTDIR | Out-Null

    # === Copy build artifacts ===
    Copy-Item "release\sioyek.exe"                 -Destination (Join-Path $OUTDIR "sioyek.exe")            -Force
    Copy-Item "pdf_viewer\keys.config"             -Destination (Join-Path $OUTDIR "keys.config")           -Force
    Copy-Item "pdf_viewer\prefs.config"            -Destination (Join-Path $OUTDIR "prefs.config")          -Force
    Copy-Item "pdf_viewer\shaders"                 -Destination (Join-Path $OUTDIR "shaders") -Recurse -Force
    Copy-Item "tutorial.pdf"                       -Destination (Join-Path $OUTDIR "tutorial.pdf")          -Force
    & windeployqt (Join-Path $OUTDIR "sioyek.exe")
    Copy-Item "windows_runtime\vcruntime140_1.dll" -Destination (Join-Path $OUTDIR "vcruntime140_1.dll")    -Force
    Copy-Item "windows_runtime\libssl-1_1-x64.dll" -Destination (Join-Path $OUTDIR "libssl-1_1-x64.dll")    -Force
    Copy-Item "windows_runtime\libcrypto-1_1-x64.dll" `
                                                  -Destination (Join-Path $OUTDIR "libcrypto-1_1-x64.dll") -Force

    # === portable vs non-portable packaging ===
    if ($Mode -and $Mode.ToLower() -eq "portable") {
        Copy-Item "pdf_viewer\keys_user.config"    -Destination (Join-Path $OUTDIR "keys_user.config")      -Force
        Copy-Item "pdf_viewer\prefs_user.config"   -Destination (Join-Path $OUTDIR "prefs_user.config")     -Force
        & 7z "a" "$OUTNAME-portable.zip" $OUTDIR
    }
    else {
        & 7z "a" "$OUTNAME.zip" $OUTDIR
    }

} *>&1 | Tee-Object -FilePath $globalLog -Append

# After build finishes, copy log into OUTDIR as well
if (Test-Path $OUTDIR) {
    $outLog = Join-Path $OUTDIR "build_$ts.log"
    Copy-Item $globalLog $outLog -Force
    Write-Host ""
    Write-Host "Build log saved to:"
    Write-Host "  $globalLog"
    Write-Host "  $outLog"
}
else {
    Write-Warning "Build output directory '$OUTDIR' does not exist; log only at $globalLog"
}
