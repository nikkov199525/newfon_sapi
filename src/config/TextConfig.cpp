#include "TextConfig.h"
#include "IniFile.h"
#include "ParamReader.h"
#include <windows.h>
#include <sstream>
#include <vector>
#include <algorithm>
static std::wstring Lower(std::wstring s) {
    if(!s.empty()) CharLowerBuffW(s.data(),static_cast<DWORD>(s.size()));
    return s;
}
static bool Word(wchar_t c) {
    return (c>=L'a' && c<=L'z') || (c>=L'A' && c<=L'Z') ||
        (c>=0x410 && c<=0x44f) || c==0x401 || c==0x451 || c==L'+' || c==0x301;
}
std::wstring ApplyUserDictionary(const std::wstring& text) {
    std::wistringstream f(ReadUnicodeFile(ParamReader::DictionaryPath()));
    std::wstring line;
    IniSection dict;
    while(std::getline(f,line)) {
        auto start=line.find_first_not_of(L" \t\r");
        if(start==line.npos || line[start]==L';') continue;
        auto space=line.find_first_of(L" \t",start);
        if(space==line.npos) continue;
        auto value=line.find_first_not_of(L" \t",space);
        if(value==line.npos) continue;
        auto end=line.find_last_not_of(L" \t\r");
        dict[Lower(line.substr(start,space-start))]=line.substr(value,end-value+1);
    }
    std::wstring out;
    for(size_t i=0;i<text.size();) {
        if(!Word(text[i])) {out+=text[i++];continue;}
        size_t end=i+1;while(end<text.size() && Word(text[end])) ++end;
        auto token=text.substr(i,end-i);auto it=dict.find(Lower(token));
        out+=it==dict.end()?token:it->second;i=end;
    }
    return out;
}
std::wstring ApplyConfiguredSymbols(const std::wstring& text,bool singleMode) {
    auto map=IniFile(ParamReader::PrefsPath()).Section(L"symbols");
    struct Replacement {std::wstring from,to;bool letter;};
    std::vector<Replacement> replacements;
    for(const auto& item:map) {
        auto colon=item.second.rfind(L':');
        if(item.first.empty() || colon==item.second.npos) continue;
        auto mode=item.second.substr(colon+1);
        // A letter (ѣ = е) is spelled inside words, so it gets no padding; spelled
        // alone it keeps its name from the letter tabs unless mode 0 says otherwise.
        bool letter=std::all_of(item.first.begin(),item.first.end(),[](wchar_t c){return IsCharAlphaW(c)!=FALSE;});
        bool use=singleMode?(mode==L"0" || (mode==L"1" && !letter)):mode==L"1";
        if(use) replacements.push_back({item.first,item.second.substr(0,colon),letter});
    }
    std::sort(replacements.begin(),replacements.end(),[](const auto& a,const auto& b){return a.from.size()>b.from.size();});
    // IniFile lowercases keys, so match against lowercased text.
    const std::wstring lower=Lower(text);
    std::wstring out;
    for(size_t i=0;i<text.size();) {
        bool found=false;
        for(const auto& r:replacements) if(lower.compare(i,r.from.size(),r.from)==0) {
            out+=r.letter?r.to:L" "+r.to+L" ";i+=r.from.size();found=true;break;
        }
        if(!found) out+=text[i++];
    }
    return out;
}
