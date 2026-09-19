#pragma once

#include <windows.h>

#ifdef RUTTS_RULEX_EXPORTS
#define RUTTS_RULEX_API extern "C" __declspec(dllexport)
#else
#define RUTTS_RULEX_API extern "C"
#endif

#define RUTTS_RULEX_CALL __cdecl

// Opaque handle returned by newfon_rulex_create.
using newfon_rulex_handle = void*;

RUTTS_RULEX_API newfon_rulex_handle RUTTS_RULEX_CALL newfon_rulex_create();
RUTTS_RULEX_API void RUTTS_RULEX_CALL newfon_rulex_destroy(newfon_rulex_handle handle);
RUTTS_RULEX_API BOOL RUTTS_RULEX_CALL newfon_rulex_ensure_loaded(newfon_rulex_handle handle, const wchar_t* archDir);
RUTTS_RULEX_API BOOL RUTTS_RULEX_CALL newfon_rulex_has_rulex(newfon_rulex_handle handle);

// Returns required buffer size (including null terminator).
// If outBuf is null or outChars is too small, only required size is returned.
RUTTS_RULEX_API int RUTTS_RULEX_CALL newfon_rulex_apply_to_russian_words(
    newfon_rulex_handle handle, const wchar_t* text, wchar_t* outBuf, int outChars);

#if defined(RUTTS_RULEX_EXPORTS) && defined(_M_IX86)
#pragma comment(linker, "/export:newfon_rulex_create=_newfon_rulex_create")
#pragma comment(linker, "/export:newfon_rulex_destroy=_newfon_rulex_destroy")
#pragma comment(linker, "/export:newfon_rulex_ensure_loaded=_newfon_rulex_ensure_loaded")
#pragma comment(linker, "/export:newfon_rulex_has_rulex=_newfon_rulex_has_rulex")
#pragma comment(linker, "/export:newfon_rulex_apply_to_russian_words=_newfon_rulex_apply_to_russian_words")
#elif defined(RUTTS_RULEX_EXPORTS)
#pragma comment(linker, "/export:newfon_rulex_create")
#pragma comment(linker, "/export:newfon_rulex_destroy")
#pragma comment(linker, "/export:newfon_rulex_ensure_loaded")
#pragma comment(linker, "/export:newfon_rulex_has_rulex")
#pragma comment(linker, "/export:newfon_rulex_apply_to_russian_words")
#endif

