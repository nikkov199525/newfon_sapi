cmake_minimum_required(VERSION 3.24)

# Script mode keeps the two architectures in separate caches. Both this script
# and build_release.cmd can be invoked from any working directory.
get_filename_component(SOURCE_DIR "${CMAKE_CURRENT_LIST_DIR}/.." ABSOLUTE)
if(DEFINED ENV{LLVM_MINGW} AND NOT "$ENV{LLVM_MINGW}" STREQUAL "")
  set(ENV{PATH} "$ENV{LLVM_MINGW}/bin;$ENV{PATH}")
endif()
find_program(LLVM_CXX NAMES x86_64-w64-mingw32-clang++)
find_program(LLVM_X86_CXX NAMES i686-w64-mingw32-clang++)
if(NOT LLVM_CXX OR NOT LLVM_X86_CXX)
  message(FATAL_ERROR "LLVM-MinGW not found. Add its bin to PATH or set LLVM_MINGW.")
endif()
get_filename_component(CMAKE_BIN "${CMAKE_COMMAND}" DIRECTORY)
find_program(CTEST_EXECUTABLE NAMES ctest HINTS "${CMAKE_BIN}" REQUIRED)

function(run_step)
  execute_process(COMMAND ${ARGV} WORKING_DIRECTORY "${SOURCE_DIR}" RESULT_VARIABLE result)
  if(NOT result STREQUAL "0")
    list(JOIN ARGV " " command)
    message(FATAL_ERROR "Release step failed (${result}): ${command}")
  endif()
endfunction()

foreach(arch x86 x64)
  set(build_dir "${SOURCE_DIR}/build/${arch}")
  set(first_configure)
  if(NOT EXISTS "${build_dir}/CMakeCache.txt")
    list(APPEND first_configure -G "MinGW Makefiles"
      "-DCMAKE_TOOLCHAIN_FILE=${SOURCE_DIR}/cmake/mingw-${arch}.cmake")
  endif()
  # Reassert Release, tests and configurer even after a developer changed the
  # cache. Configuring on every run also refreshes the installer's date.
  run_step("${CMAKE_COMMAND}" -S "${SOURCE_DIR}" -B "${build_dir}" ${first_configure}
    -DCMAKE_BUILD_TYPE=Release -DBUILD_TESTING=ON -DNEWFON_BUILD_CONFIGURATOR=ON
    -DNEWFON_REQUIRE_RELEASE_TOOLS=ON)
  run_step("${CMAKE_COMMAND}" --build "${build_dir}" --parallel)
  # Keep the existing order: both engines, then the x64 configurer test.
  run_step("${CTEST_EXECUTABLE}" --test-dir "${build_dir}" --output-on-failure -R "^integration$")
endforeach()
run_step("${CTEST_EXECUTABLE}" --test-dir "${SOURCE_DIR}/build/x64"
  --output-on-failure -R "^configurer_roundtrip$")
run_step("${CMAKE_COMMAND}" --build "${SOURCE_DIR}/build/x64" --target installer)
message(STATUS "Installer is in ${SOURCE_DIR}/build/x64/installer")
