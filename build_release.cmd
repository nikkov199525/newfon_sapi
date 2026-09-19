@echo off
rem Full release: x86 and x64 trees, tests, then the Inno Setup package
rem build\x64\installer\newfon_sapi_<version>_setup.exe.
rem Needs cmake, LLVM-MinGW (in PATH or LLVM_MINGW), PureBasic and Inno Setup 6.
setlocal EnableExtensions
cd /d "%~dp0"

if defined LLVM_MINGW set "PATH=%LLVM_MINGW%\bin;%PATH%"
where /q x86_64-w64-mingw32-clang || (
  echo [ERROR] LLVM-MinGW not found. Add its bin to PATH or set LLVM_MINGW.
  exit /b 1
)

call :build x86 || exit /b 1
call :build x64 || exit /b 1
python tests\configurer_roundtrip.py build\x64\bin || exit /b 1
cmake --build build\x64 --target installer || exit /b 1
echo [OK] Installer is in build\x64\installer
exit /b 0

:build
rem Configured every time: the installer is versioned by the current date.
rem The toolchain is only for the first run; repeating it warns about an unused variable.
if exist "build\%1\CMakeCache.txt" (
  cmake -S . -B "build\%1" || exit /b 1
) else (
  cmake -S . -B "build\%1" -G "MinGW Makefiles" -DCMAKE_BUILD_TYPE=Release ^
    "-DCMAKE_TOOLCHAIN_FILE=%CD%\cmake\mingw-%1.cmake" || exit /b 1
)
cmake --build "build\%1" -j || exit /b 1
ctest --test-dir "build\%1" --output-on-failure || exit /b 1
exit /b 0
