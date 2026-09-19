#include "IniFile.h"
#include <windows.h>
#include <filesystem>
#include <fstream>
#include <sstream>
#include <cwctype>
#include <cerrno>
#include <climits>
static std::wstring Lower(std::wstring s) {
    if (!s.empty()) CharLowerBuffW(s.data(), static_cast<DWORD>(s.size()));
    return s;
}
static std::wstring Trim(std::wstring s) {
    auto start = s.find_first_not_of(L" \t\r\n");
    if(start == s.npos) return {};
    return s.substr(start, s.find_last_not_of(L" \t\r\n")-start+1);
}
std::wstring ReadUnicodeFile(const std::wstring& path) {
    std::ifstream f(std::filesystem::path(path), std::ios::binary);
    std::string bytes((std::istreambuf_iterator<char>(f)), {});
    if(bytes.size() >= 2 && static_cast<unsigned char>(bytes[0]) == 255 && static_cast<unsigned char>(bytes[1]) == 254) {
        std::wstring out;
        for(size_t i=2;i+1<bytes.size();i+=2)
            out.push_back(static_cast<unsigned char>(bytes[i]) | (static_cast<unsigned char>(bytes[i+1]) << 8));
        return out;
    }
    if(bytes.compare(0,3,"\xef\xbb\xbf")==0) bytes.erase(0,3);
    if(bytes.empty() || bytes.size()>INT_MAX) return {};
    int count=MultiByteToWideChar(CP_UTF8, MB_ERR_INVALID_CHARS, bytes.data(), static_cast<int>(bytes.size()), nullptr,0);
    if(count<=0) return {};
    std::wstring out(count,0);
    MultiByteToWideChar(CP_UTF8, MB_ERR_INVALID_CHARS, bytes.data(), static_cast<int>(bytes.size()),out.data(),count);
    return out;
}
IniFile::IniFile(const std::wstring& path) {
    std::wistringstream stream(ReadUnicodeFile(path));
    std::wstring line, section;
    while(std::getline(stream,line)) {
        line=Trim(line);
        if(line.empty() || line[0]==L';' || line[0]==L'#') continue;
        if(line.front()==L'[' && line.back()==L']') {section=Lower(Trim(line.substr(1,line.size()-2)));continue;}
        auto pos=line.find(L'=');
        if(pos==line.npos) continue;
        auto value=Trim(line.substr(pos+1));
        if(value.size()>=2 && ((value.front()==L'"' && value.back()==L'"') || (value.front()==L'\'' && value.back()==L'\''))) value=value.substr(1,value.size()-2);
        sections[section][Lower(Trim(line.substr(0,pos)))]=value;
    }
}
IniSection IniFile::Section(const std::wstring& name) const {
    auto it=sections.find(Lower(name));
    return it==sections.end()?IniSection{}:it->second;
}
int IniFile::Integer(const wchar_t* section,const wchar_t* key,int fallback,int min,int max) const {
    auto values=Section(section);auto it=values.find(Lower(key));
    if(it==values.end()) return fallback;
    wchar_t* end=nullptr;errno=0;
    long n=wcstol(it->second.c_str(),&end,10);
    return errno || end==it->second.c_str() || *end || n<min || n>max ? fallback : static_cast<int>(n);
}
bool IniFile::Boolean(const wchar_t* section,const wchar_t* key,bool fallback) const {
    auto values=Section(section);auto it=values.find(Lower(key));
    if(it==values.end()) return fallback;
    auto v=Lower(it->second);
    if(v==L"true" || v==L"1" || v==L"yes" || v==L"on") return true;
    if(v==L"false" || v==L"0" || v==L"no" || v==L"off") return false;
    return fallback;
}
