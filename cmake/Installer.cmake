# "installer" target: packs this tree (x64) and the x86 tree into one Inno Setup
# package. Build the x86 tree first; build_release.cmd does both.
find_program(ISCC_EXECUTABLE NAMES ISCC.exe iscc.exe HINTS
 "C:/Program Files (x86)/Inno Setup 6" "C:/Program Files/Inno Setup 6" "$ENV{LOCALAPPDATA}/Programs/Inno Setup 6")
set(NEWFON_X86_BIN_DIR "${CMAKE_SOURCE_DIR}/build/x86/bin" CACHE PATH "bin directory of the x86 build tree")
if(CMAKE_SIZEOF_VOID_P EQUAL 8 AND ISCC_EXECUTABLE AND NEWFON_BUILD_CONFIGURATOR)
 # The installer is versioned by the day it is built, as the 2019 one was.
 string(TIMESTAMP SETUP_VERSION "%Y.%m.%d")
 set(SETUP "${CMAKE_BINARY_DIR}/installer/Setup-Newfon SAPI-v${SETUP_VERSION}-X86-x64.exe")
 file(TO_NATIVE_PATH "${CMAKE_SOURCE_DIR}" NATIVE_SOURCE)
 file(TO_NATIVE_PATH "${CMAKE_BINARY_DIR}/bin" NATIVE_X64)
 file(TO_NATIVE_PATH "${NEWFON_X86_BIN_DIR}" NATIVE_X86)
 file(TO_NATIVE_PATH "${CMAKE_BINARY_DIR}/installer" NATIVE_OUTPUT)
 set(X86_FILES newfon_core.dll newfon_rulex.dll rulex.dll newfon_sapi.dll)
 list(TRANSFORM X86_FILES PREPEND "${NEWFON_X86_BIN_DIR}/")
 add_custom_command(OUTPUT "${SETUP}"
  COMMAND "${ISCC_EXECUTABLE}" /Qp
   # No quotes (ISCC would keep the escaped ones) and no underscore in the
   # name, which ISCC mangles into something else.
   "/DSetupVersion=${SETUP_VERSION}"
   "/DSourceRoot=${NATIVE_SOURCE}"
   "/DX64Bin=${NATIVE_X64}"
   "/DX86Bin=${NATIVE_X86}"
   "/DOutputDir=${NATIVE_OUTPUT}"
   "${CMAKE_SOURCE_DIR}/installer/newfon_sapi.iss"
  DEPENDS installer/newfon_sapi.iss "${CMAKE_BINARY_DIR}/bin/prefs.ini" ${X86_FILES}
   docs/Russian.html
   newfon_core newfon_rulex newfon_sapi rulex rulex_database configurator
  VERBATIM)
 add_custom_target(installer DEPENDS "${SETUP}")
endif()
