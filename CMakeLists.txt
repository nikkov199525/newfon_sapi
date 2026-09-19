cmake_minimum_required(VERSION 3.24)
project(NewfonSAPI VERSION 1.0.0 LANGUAGES C CXX)
if(NOT WIN32 OR NOT MINGW)
  message(FATAL_ERROR "Use LLVM-MinGW on Windows; see README.md")
endif()
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin")
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin")
add_link_options(-static)

# Layout: external/ and Newfon_core/ are submodules, src/ is this bridge,
# configurer/ the PureBasic settings program, config/ the shipped defaults.
set(EXT "${CMAKE_SOURCE_DIR}/external")
set(CORE "${CMAKE_SOURCE_DIR}/Newfon_core")
set(LMDB "${EXT}/lmdb/libraries/liblmdb")
set(RULEX "${EXT}/rulex")
foreach(SUBMODULE "${CORE}/src" "${LMDB}" "${RULEX}/src" "${EXT}/pcre2/src" "${EXT}/libsamplerate")
 if(NOT EXISTS "${SUBMODULE}")
  message(FATAL_ERROR "${SUBMODULE} is missing. Run: git submodule update --init --recursive")
 endif()
endforeach()

# --- Newfon core: the synthesizer itself ------------------------------------
file(GLOB CORE_SOURCES CONFIGURE_DEPENDS "${CORE}/src/*.c")
add_library(newfon_core SHARED ${CORE_SOURCES})
target_include_directories(newfon_core PUBLIC "${CORE}/include")
set_target_properties(newfon_core PROPERTIES PREFIX "")

# --- Resampling: core rate -> the rate handed to SAPI -----------------------
add_library(resampler STATIC ${EXT}/libsamplerate/samplerate.c ${EXT}/libsamplerate/src_linear.c ${EXT}/libsamplerate/src_zoh.c)
target_include_directories(resampler PUBLIC "${EXT}/libsamplerate")
target_compile_definitions(resampler PRIVATE HAVE_LRINT=1 HAVE_LRINTF=1)

# --- RuLex: the stress dictionary and its LMDB storage ----------------------
set(PCRE2_BUILD_PCRE2_8 ON CACHE BOOL "" FORCE)
set(PCRE2_BUILD_PCRE2_16 OFF CACHE BOOL "" FORCE)
set(PCRE2_BUILD_PCRE2_32 OFF CACHE BOOL "" FORCE)
set(PCRE2_BUILD_PCRE2GREP OFF CACHE BOOL "" FORCE)
set(PCRE2_BUILD_TESTS OFF CACHE BOOL "" FORCE)
set(BUILD_SHARED_LIBS OFF CACHE BOOL "" FORCE)
add_subdirectory("${EXT}/pcre2" EXCLUDE_FROM_ALL)
include(cmake/LmdbPatch.cmake)
# access_utf8.c makes rulex open a database along a non-ASCII path.
add_library(rulex_objects STATIC
 ${RULEX}/src/lexdb.c ${RULEX}/src/coder.c
 ${LMDB_PATCHED} ${LMDB}/midl.c ${LMDB}/module.c
 src/rulex/access_utf8.c)
target_include_directories(rulex_objects PUBLIC "${LMDB}" "${RULEX}/src")
target_compile_definitions(rulex_objects PUBLIC PCRE2_STATIC)
if(CMAKE_SIZEOF_VOID_P EQUAL 4)
 # 32-bit rulex reads the same database as the 64-bit one through VL32.
 target_compile_definitions(rulex_objects PUBLIC MDB_VL32)
endif()
target_link_libraries(rulex_objects PUBLIC pcre2-posix pcre2-8 pthread)
add_library(rulex SHARED src/rulex/rulex.def)
set_target_properties(rulex PROPERTIES LINKER_LANGUAGE C PREFIX "")
target_link_libraries(rulex PRIVATE -Wl,--whole-archive rulex_objects -Wl,--no-whole-archive)

# rulex.db is built from the dictionary sources of the rulex submodule.
add_executable(lexholder ${RULEX}/src/lexholder.c)
target_link_libraries(lexholder PRIVATE rulex_objects)
set(DATA "${RULEX}/data")
add_custom_command(OUTPUT "${CMAKE_BINARY_DIR}/bin/rulex.db"
 COMMAND ${CMAKE_COMMAND} -E rm -f "${CMAKE_BINARY_DIR}/bin/rulex.db"
 COMMAND $<TARGET_FILE:lexholder> -f "${DATA}/explicit.dict" -X "${CMAKE_BINARY_DIR}/bin/rulex.db"
 COMMAND $<TARGET_FILE:lexholder> -f "${DATA}/implicit.dict" -M "${CMAKE_BINARY_DIR}/bin/rulex.db"
 COMMAND $<TARGET_FILE:lexholder> -f "${DATA}/lexicon.rules" -L "${CMAKE_BINARY_DIR}/bin/rulex.db"
 COMMAND $<TARGET_FILE:lexholder> -f "${DATA}/general.rules" -G "${CMAKE_BINARY_DIR}/bin/rulex.db"
 COMMAND $<TARGET_FILE:lexholder> -f "${DATA}/prefix.rules" -P "${CMAKE_BINARY_DIR}/bin/rulex.db"
 COMMAND $<TARGET_FILE:lexholder> -f "${DATA}/correction.rules" -C "${CMAKE_BINARY_DIR}/bin/rulex.db"
 DEPENDS lexholder ${DATA}/explicit.dict ${DATA}/implicit.dict ${DATA}/lexicon.rules ${DATA}/general.rules ${DATA}/prefix.rules ${DATA}/correction.rules VERBATIM)
add_custom_target(rulex_database ALL DEPENDS "${CMAKE_BINARY_DIR}/bin/rulex.db")

# The engine talks to rulex through this wrapper, never to rulex.dll directly.
add_library(newfon_rulex SHARED src/rulex/RulexApi.cpp)
target_include_directories(newfon_rulex PUBLIC src/rulex)
target_compile_definitions(newfon_rulex PRIVATE RUTTS_RULEX_EXPORTS UNICODE _UNICODE)
set_target_properties(newfon_rulex PROPERTIES PREFIX "")

# --- Settings, shared by the engine and the tests ---------------------------
add_library(newfon_config STATIC src/config/ParamReader.cpp src/config/IniFile.cpp src/config/TextConfig.cpp)
target_include_directories(newfon_config PUBLIC src/config "${CORE}/include")
target_compile_definitions(newfon_config PUBLIC UNICODE _UNICODE NOMINMAX)
target_link_libraries(newfon_config PUBLIC shell32)
# Generates bin/prefs.ini and the defaults compiled into the engine.
include(cmake/Defaults.cmake)

# --- The SAPI 5 engine ------------------------------------------------------
file(GLOB SAPI_SOURCES CONFIGURE_DEPENDS src/sapi/*.cpp)
add_library(newfon_sapi SHARED ${SAPI_SOURCES} src/sapi/newfon_sapi.def)
target_include_directories(newfon_sapi PRIVATE src/sapi src/rulex)
target_compile_definitions(newfon_sapi PRIVATE _WIN32_WINNT=0x0A00)
target_link_libraries(newfon_sapi PRIVATE newfon_config resampler ole32 oleaut32 shlwapi advapi32 uuid)
target_link_options(newfon_sapi PRIVATE -Wl,--enable-stdcall-fixup)
set_target_properties(newfon_sapi PROPERTIES PREFIX "")

# --- Configurer (PureBasic) -------------------------------------------------
find_program(PB_COMPILER NAMES pbcompiler.exe pbcompilerc.exe HINTS "C:/Program Files/PureBasic/Compilers" "C:/Program Files (x86)/PureBasic/Compilers")
option(NEWFON_BUILD_CONFIGURATOR "Build the PureBasic configurator" ON)
if(NEWFON_BUILD_CONFIGURATOR)
 if(NOT PB_COMPILER)
  message(FATAL_ERROR "Set PB_COMPILER to the PureBasic compiler")
 endif()
 add_custom_command(OUTPUT "${CMAKE_BINARY_DIR}/bin/NewfonConfigurer.exe"
  COMMAND "${PB_COMPILER}" "${CMAKE_SOURCE_DIR}/configurer/Configurer.pb" /OUTPUT "${CMAKE_BINARY_DIR}/bin/NewfonConfigurer.exe"
  DEPENDS configurer/Configurer.pb configurer/extras/PrefsExtras.pb WORKING_DIRECTORY "${CMAKE_SOURCE_DIR}/configurer" VERBATIM)
 add_custom_target(configurator ALL DEPENDS "${CMAKE_BINARY_DIR}/bin/NewfonConfigurer.exe")
 # The "Документация" button and F1 open docs next to the configurer.
 file(COPY docs DESTINATION "${CMAKE_BINARY_DIR}/bin")
 install(PROGRAMS "${CMAKE_BINARY_DIR}/bin/NewfonConfigurer.exe" DESTINATION .)
endif()

# --- Packaging --------------------------------------------------------------
# "installer" target: the Inno Setup package from both build trees.
include(cmake/Installer.cmake)
install(TARGETS newfon_core newfon_rulex newfon_sapi rulex RUNTIME DESTINATION . LIBRARY DESTINATION .)
install(FILES "${CMAKE_BINARY_DIR}/bin/rulex.db" "${CMAKE_BINARY_DIR}/bin/prefs.ini" DESTINATION .)
install(DIRECTORY LICENSES docs DESTINATION .)

# --- Tests ------------------------------------------------------------------
include(CTest)
if(BUILD_TESTING)
 add_executable(newfon_integration tests/integration.cpp src/sapi/RulexClient.cpp src/sapi/WinUtil.cpp)
 target_include_directories(newfon_integration PRIVATE src/sapi src/rulex)
 target_link_libraries(newfon_integration PRIVATE newfon_config ole32 uuid advapi32)
 add_dependencies(newfon_integration newfon_sapi newfon_core newfon_rulex rulex rulex_database)
 add_test(NAME integration COMMAND newfon_integration "${CMAKE_BINARY_DIR}/bin")
endif()
