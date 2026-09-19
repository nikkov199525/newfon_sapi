#include "ComReg.h"

#include "Guid.h"

#include <windows.h>
#include <shlwapi.h>
#include <objbase.h>     // StringFromGUID2
#include <string>

#pragma comment(lib, "Shlwapi.lib")

// Linker-provided symbol representing module base.
extern "C" IMAGE_DOS_HEADER __ImageBase;

namespace {

static HRESULT HrFromWin32(LONG rc)
{
    if (rc == ERROR_SUCCESS) return S_OK;
    return HRESULT_FROM_WIN32(static_cast<DWORD>(rc));
}

static HRESULT WriteRegString(HKEY root,
                              const std::wstring& sub,
                              const std::wstring& name,
                              const std::wstring& val)
{
    HKEY h = nullptr;

    const LONG rcCreate = RegCreateKeyExW(
        root,
        sub.c_str(),
        0,
        nullptr,
        0,
        KEY_WRITE,
        nullptr,
        &h,
        nullptr);

    if (rcCreate != ERROR_SUCCESS)
        return HrFromWin32(rcCreate);

    const BYTE* data = reinterpret_cast<const BYTE*>(val.c_str());
    const size_t bytes = (val.size() + 1) * sizeof(wchar_t);

    // RegSetValueExW expects DWORD size.
    const DWORD cb = (bytes > static_cast<size_t>(MAXDWORD))
        ? MAXDWORD
        : static_cast<DWORD>(bytes);

    const wchar_t* valueName = name.empty() ? nullptr : name.c_str();

    const LONG rcSet = RegSetValueExW(
        h,
        valueName,
        0,
        REG_SZ,
        data,
        cb);

    RegCloseKey(h);
    return HrFromWin32(rcSet);
}

static HRESULT DeleteKeyTree(HKEY root, const std::wstring& sub)
{
    const LONG rc = SHDeleteKeyW(root, sub.c_str());
    if (rc == ERROR_FILE_NOT_FOUND)
        return S_OK;
    return HrFromWin32(rc);
}

static std::wstring GuidToString(const GUID& g)
{
    wchar_t buf[64]{};
    const int n = StringFromGUID2(g, buf, static_cast<int>(std::size(buf)));
    if (n <= 0)
        return std::wstring();
    return std::wstring(buf);
}

// Minimal SAPI voice token registration.
// SAPI enumerates voices from:
//   HKLM\SOFTWARE\Microsoft\Speech\Voices\Tokens
// and reads the "CLSID" value for COM activation.
static HRESULT RegisterSapiToken(const wchar_t* name, DWORD voice, const wchar_t* gender)
{
    const std::wstring tokenName = name;
    const std::wstring base = L"SOFTWARE\\Microsoft\\Speech\\Voices\\Tokens\\" + tokenName;
    const std::wstring clsid = GuidToString(CLSID_NewfonSapi);

    if (clsid.empty())
        return E_FAIL;

    // Default value helps some clients that display the token name
    HRESULT hr = WriteRegString(HKEY_LOCAL_MACHINE, base, L"", tokenName);
    if (FAILED(hr)) return hr;

    hr = WriteRegString(HKEY_LOCAL_MACHINE, base, L"CLSID", clsid);
    if (FAILED(hr)) return hr;

    HKEY key = nullptr;
    LONG rc = RegOpenKeyExW(HKEY_LOCAL_MACHINE, base.c_str(), 0, KEY_SET_VALUE, &key);
    if (rc != ERROR_SUCCESS) return HrFromWin32(rc);
    rc = RegSetValueExW(key, L"VoiceIndex", 0, REG_DWORD, reinterpret_cast<const BYTE*>(&voice), sizeof(voice));
    RegCloseKey(key);
    if (rc != ERROR_SUCCESS) return HrFromWin32(rc);
    const std::wstring attrs = base + L"\\Attributes";

    hr = WriteRegString(HKEY_LOCAL_MACHINE, attrs, L"Name", tokenName);
    if (FAILED(hr)) return hr;

    hr = WriteRegString(HKEY_LOCAL_MACHINE, attrs, L"Vendor", L"Newfon");
    if (FAILED(hr)) return hr;

    // Language is stored as a hex string (LCID). 0x0419 = Russian.
    hr = WriteRegString(HKEY_LOCAL_MACHINE, attrs, L"Language", L"0419");
    if (FAILED(hr)) return hr;

    // Optional, but common attributes:
    (void)WriteRegString(HKEY_LOCAL_MACHINE, attrs, L"Gender", gender);
    (void)WriteRegString(HKEY_LOCAL_MACHINE, attrs, L"Age", L"Adult");

    return S_OK;
}

static HRESULT UnregisterSapiToken()
{
    HRESULT result = S_OK;
    for (const auto* name : {L"newfon male1", L"newfon male2", L"newfon female1", L"newfon female2"}) {
        HRESULT hr = DeleteKeyTree(HKEY_LOCAL_MACHINE, std::wstring(L"SOFTWARE\\Microsoft\\Speech\\Voices\\Tokens\\") + name);
        if (FAILED(hr)) result = hr;
    }
    return result;
}

static HRESULT GetThisModulePath(std::wstring& out)
{
    wchar_t buf[MAX_PATH]{};
    const DWORD n = GetModuleFileNameW(reinterpret_cast<HMODULE>(&__ImageBase), buf, static_cast<DWORD>(std::size(buf)));

    if (n == 0)
        return HRESULT_FROM_WIN32(GetLastError());

    // If truncated, Windows returns buffer size (or size-1 in some cases depending on version).
    if (n >= std::size(buf) - 1)
        return HRESULT_FROM_WIN32(ERROR_INSUFFICIENT_BUFFER);

    out.assign(buf, n);
    return S_OK;
}

} // namespace

HRESULT RegisterComServer()
{
    const std::wstring clsid = GuidToString(CLSID_NewfonSapi);
    if (clsid.empty())
        return E_FAIL;

    const std::wstring base = L"CLSID\\" + clsid;

    std::wstring dllPath;
    HRESULT hr = GetThisModulePath(dllPath);
    if (FAILED(hr)) return hr;

    hr = WriteRegString(HKEY_CLASSES_ROOT, base, L"", L"Newfon SAPI");
    if (FAILED(hr)) return hr;

    hr = WriteRegString(HKEY_CLASSES_ROOT, base + L"\\InprocServer32", L"", dllPath);
    if (FAILED(hr)) return hr;

    hr = WriteRegString(HKEY_CLASSES_ROOT, base + L"\\InprocServer32", L"ThreadingModel", L"Both");
    if (FAILED(hr)) return hr;

    // Leftovers of the previous CLSID would keep pointing at this DLL.
    const std::wstring legacy = GuidToString(CLSID_NewfonSapiLegacy);
    if (!legacy.empty()) (void)DeleteKeyTree(HKEY_CLASSES_ROOT, L"CLSID\\" + legacy);

    // Token lives under HKLM, so requires admin.
    hr = RegisterSapiToken(L"newfon male1", 0, L"Male");
    if (SUCCEEDED(hr)) hr = RegisterSapiToken(L"newfon male2", 2, L"Male");
    if (SUCCEEDED(hr)) hr = RegisterSapiToken(L"newfon female1", 1, L"Female");
    if (SUCCEEDED(hr)) hr = RegisterSapiToken(L"newfon female2", 3, L"Female");
    return hr;
}

HRESULT UnregisterComServer()
{
    const std::wstring clsid = GuidToString(CLSID_NewfonSapi);
    if (clsid.empty())
        return E_FAIL;

    const HRESULT hr1 = DeleteKeyTree(HKEY_CLASSES_ROOT, L"CLSID\\" + clsid);
    const std::wstring legacy = GuidToString(CLSID_NewfonSapiLegacy);
    if (!legacy.empty()) (void)DeleteKeyTree(HKEY_CLASSES_ROOT, L"CLSID\\" + legacy);
    const HRESULT hr2 = UnregisterSapiToken();

    return FAILED(hr1) ? hr1 : hr2;
}
