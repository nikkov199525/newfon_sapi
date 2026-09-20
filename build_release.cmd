@echo off
rem Keep the traditional entry point; CMake owns the complete release workflow.
setlocal EnableExtensions
cmake -P "%~dp0cmake\Release.cmake"
exit /b %errorlevel%
