#include "ParamReader.h"
#include "IniFile.h"
#include "Defaults.h"
#include <windows.h>
#include <shlobj.h>
#include <filesystem>
#include <fstream>
namespace {
std::filesystem::path ConfigDir() {
    // Explicit override also makes integration tests independent of user settings.
    wchar_t overridePath[32768]{};
    DWORD n=GetEnvironmentVariableW(L"NEWFON_CONFIG_DIR",overridePath,32768);
    if(n>0 && n<32768) return overridePath;
    // Per-user settings in AppData\Roaming, where the configurer saves them.
    wchar_t path[MAX_PATH]{};
    if(FAILED(SHGetFolderPathW(nullptr,CSIDL_APPDATA,nullptr,SHGFP_TYPE_CURRENT,path))) return {};
    return std::filesystem::path(path)/L"NewfonSAPI";
}
void EnsureFile(const std::wstring& path,const wchar_t* contents) {
    std::error_code ec;
    if(std::filesystem::exists(path,ec)) return;
    std::filesystem::create_directories(std::filesystem::path(path).parent_path(),ec);
    // CREATE_NEW avoids truncating a file created by another SAPI host.
    HANDLE h=CreateFileW(path.c_str(),GENERIC_WRITE,FILE_SHARE_READ,nullptr,CREATE_NEW,FILE_ATTRIBUTE_NORMAL,nullptr);
    if(h==INVALID_HANDLE_VALUE) return;
    int n=WideCharToMultiByte(CP_UTF8,0,contents,-1,nullptr,0,nullptr,nullptr);
    std::string bytes(n,0);
    WideCharToMultiByte(CP_UTF8,0,contents,-1,bytes.data(),n,nullptr,nullptr);
    DWORD written;WriteFile(h,bytes.data(),static_cast<DWORD>(n-1),&written,nullptr);CloseHandle(h);
}
}
std::wstring ParamReader::IniPath(){return (ConfigDir()/L"prefs.ini").wstring();}
std::wstring ParamReader::PrefsPath(){return (ConfigDir()/L"prefs.ini").wstring();}
std::wstring ParamReader::DictionaryPath(){return (ConfigDir()/L"ru_dict.dic").wstring();}
NewfonParams ParamReader::Load() {
    EnsureFile(IniPath(),kDefaultNewfonIni);
    IniFile ini(IniPath()),prefs(PrefsPath());
    NewfonParams p;
    p.samples_per_sec=ini.Integer(L"General",L"sample_rate",kSapiDefaultRate,8000,16000);
    int mul=ini.Integer(L"General",L"interpolation_multiplier",1,1,4);
    p.interpolation_multiplier=mul==3?4:mul;
    p.interpolation_algorithm=ini.Integer(L"General",L"interpolation_algorithm",0,0,1)==0?InterpolationAlgorithm::Linear:InterpolationAlgorithm::ZeroOrderHold;
    p.use_legacy_rate_algo=ini.Boolean(L"General",L"UseLegacyRateAlgo",true);
    p.dec_sep_point=ini.Boolean(L"General",L"dec_sep_point",true);
    p.dec_sep_comma=ini.Boolean(L"General",L"dec_sep_comma",true);
    // As in the NVDA driver: 0 is off, 7 the mildest, 1 the strongest.
    p.acceleration=ini.Integer(L"General",L"accel",NEWFON_ACCEL_OFF,NEWFON_ACCEL_OFF,NEWFON_ACCEL_MAX);
    p.pause=prefs.Integer(L"General",L"pause",-1,-1,255);
    p.intonation=prefs.Integer(L"General",L"intonation",50,0,100);
    p.silence_at_begin=prefs.Integer(L"General",L"silence_at_begin",0,0,250);
    p.silence_at_end=prefs.Integer(L"General",L"silence_at_end",0,0,250);
    int mode=prefs.Integer(L"General",L"use_dictionary",2,0,3);
    p.use_rulex=mode==1 || mode==2;p.use_user_dictionary=mode==2 || mode==3;
    p.output_sample_rate=kSapiBaseOutputRate*p.interpolation_multiplier;
    return p;
}
void ParamReader::ApplyToConf(const NewfonParams& p,newfon_conf_t& conf) {
    if(p.pause>=0) conf.pause=p.pause;
    conf.inflection=p.intonation;
    conf.acceleration=p.acceleration;
    conf.flags &= ~(DEC_SEP_POINT|DEC_SEP_COMMA|USE_LEGACY_RATE_ALGO);
    if(p.dec_sep_point) conf.flags|=DEC_SEP_POINT;
    if(p.dec_sep_comma) conf.flags|=DEC_SEP_COMMA;
    if(p.use_legacy_rate_algo) conf.flags|=USE_LEGACY_RATE_ALGO;
}
