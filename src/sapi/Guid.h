#pragma once
#include <guiddef.h>

// CLSID of the original Newfon SAPI: the JAWS instructions in docs/Russian.html
// name it in sapi5x.ini, so the engine has to keep it.
// {EB63CF34-0326-464D-BDD7-FA97133068BA}
static const GUID CLSID_NewfonSapi =
{ 0xEB63CF34, 0x0326, 0x464D, {0xBD,0xD7,0xFA,0x97,0x13,0x30,0x68,0xBA} };

// The CLSID this bridge used before; unregistered so it leaves nothing behind.
// {61C54924-9E43-432B-9B5E-2B7C5B63F1C9}
static const GUID CLSID_NewfonSapiLegacy =
{ 0x61C54924, 0x9E43, 0x432B, {0x9B,0x5E,0x2B,0x7C,0x5B,0x63,0xF1,0xC9} };
