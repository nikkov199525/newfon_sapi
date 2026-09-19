#pragma once
#include <string>
#include <unordered_map>
using IniSection = std::unordered_map<std::wstring, std::wstring>;
class IniFile {
    std::unordered_map<std::wstring, IniSection> sections;
public:
    explicit IniFile(const std::wstring& path);
    IniSection Section(const std::wstring& name) const;
    int Integer(const wchar_t* section, const wchar_t* key, int fallback, int min, int max) const;
    bool Boolean(const wchar_t* section, const wchar_t* key, bool fallback) const;
};
std::wstring ReadUnicodeFile(const std::wstring& path);
