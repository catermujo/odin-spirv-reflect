@echo off

setlocal EnableDelayedExpansion

set "VENDOR_WINDOWS_ARCH=%VSCMD_ARG_TGT_ARCH%"
if not defined VENDOR_WINDOWS_ARCH set "VENDOR_WINDOWS_ARCH=%PROCESSOR_ARCHITECTURE%"
if /I "%VENDOR_WINDOWS_ARCH%"=="AMD64" set "VENDOR_WINDOWS_ARCH=x64"
if /I "%VENDOR_WINDOWS_ARCH%"=="ARM64" set "VENDOR_WINDOWS_ARCH=arm64"
if /I "%VENDOR_WINDOWS_ARCH%"=="X86" set "VENDOR_WINDOWS_ARCH=x64"
set "output_dir=windows_%VENDOR_WINDOWS_ARCH%"

if not exist SPIRV-Reflect (
    git clone --recurse-submodules --revision ef913b3ab3da1becca3cf46b15a10667c67bebe5 https://github.com/KhronosGroup/SPIRV-Reflect --depth=1 || exit /b 1
)

set source_dir=SPIRV-Reflect
set binaries_dir=build

echo Configuring build...
REM DUMBAI: Configure the checked-out upstream project instead of the wrapper folder.
cmake -S %source_dir% -B %binaries_dir% -A %VENDOR_WINDOWS_ARCH% -DSPIRV_REFLECT_EXECUTABLE=OFF -DSPIRV_REFLECT_STATIC_LIB=ON -DCMAKE_BUILD_TYPE=Release || exit /b 1

echo Building project...
REM DUMBAI: Let CMake pick the active Windows generator instead of assuming make exists.
cmake --build %binaries_dir% --config Release || exit /b 1

if not exist %output_dir% mkdir %output_dir%

set SPIRV_LIB=
for /r "%binaries_dir%" %%F in (*.lib) do (
    if /I "%%~nxF"=="spirv-reflect-static.lib" set "SPIRV_LIB=%%~fF"
)
if not defined SPIRV_LIB (
    echo ERROR: Could not find spirv-reflect-static.lib under %binaries_dir%.
    exit /b 1
)

copy /y "%SPIRV_LIB%" %output_dir%\spirv.lib >nul || exit /b 1

echo Build completed successfully!
