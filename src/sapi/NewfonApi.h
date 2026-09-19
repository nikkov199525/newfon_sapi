#pragma once
#include <windows.h>
#include <string>
#include <cstddef>

#include "newfon_core.h"

using newfon_config_init_fn = void (*)(newfon_conf_t*);
using newfon_transfer_fn = void (*)(const newfon_conf_t*, const char*, void*, size_t, newfon_callback, void*);

struct NewfonApi {
    HMODULE dll = nullptr;

    newfon_config_init_fn config_init = nullptr;

    // Required synthesis path.
    newfon_transfer_fn transfer = nullptr;

    bool LoadFromDir(const std::wstring& dir);
    void Unload();
};
