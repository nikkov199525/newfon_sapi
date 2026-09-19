#include <windows.h>
#include "NewfonSapiDdk.h"
#include "Guid.h"
#include "ParamReader.h"
#include "IniFile.h"
#include "TextConfig.h"
#include "RulexClient.h"
#include <windows.h>
#include <filesystem>
#include <fstream>
#include <iostream>
#include <vector>
#include <set>
#include <stdexcept>
#include <cstdint>
#define CHECK(x) do { if(!(x)) throw std::runtime_error(#x); } while(0)
struct Site final : ISpTTSEngineSite {
    // The engine speaks 8-bit mono by default, so audio is kept as raw bytes.
    std::vector<uint8_t> audio;
    long rate=0;
    USHORT volume=100;
    bool abort=false;
    size_t abortAfter=0;
    int bookmarks=0;
    HRESULT STDMETHODCALLTYPE QueryInterface(REFIID,void** p) override {*p=this;return S_OK;}
    ULONG STDMETHODCALLTYPE AddRef() override {return 1;}
    ULONG STDMETHODCALLTYPE Release() override {return 1;}
    HRESULT STDMETHODCALLTYPE AddEvents(const SPEVENT* events,ULONG count) override {
        for(ULONG i=0;i<count;++i) if(events[i].eEventId==SPEI_TTS_BOOKMARK) ++bookmarks;
        return S_OK;
    }
    HRESULT STDMETHODCALLTYPE GetEventInterest(ULONGLONG* p) override {*p=~0ULL;return S_OK;}
    DWORD STDMETHODCALLTYPE GetActions() override {return abort || (abortAfter && audio.size()>=abortAfter)?SPVES_ABORT:0;}
    HRESULT STDMETHODCALLTYPE Write(const void* b,ULONG size,ULONG* written) override {
        CHECK(size<=1024);
        const uint8_t* pcm=static_cast<const uint8_t*>(b);
        audio.insert(audio.end(),pcm,pcm+size);*written=size;return S_OK;
    }
    HRESULT STDMETHODCALLTYPE GetRate(long* p) override {*p=rate;return S_OK;}
    HRESULT STDMETHODCALLTYPE GetVolume(USHORT* p) override {*p=volume;return S_OK;}
    HRESULT STDMETHODCALLTYPE GetSkipInfo(SPVSKIPTYPE*,long*) override {return E_NOTIMPL;}
    HRESULT STDMETHODCALLTYPE CompleteSkip(long) override {return S_OK;}
};
static void Write(const std::filesystem::path& p,const std::string& s) {std::ofstream f(p,std::ios::binary);f<<s;CHECK(f.good());}
static uint64_t Hash(const std::vector<uint8_t>& pcm) {uint64_t n=1469598103934665603ULL;for(auto x:pcm) n=(n^x)*1099511628211ULL;return n;}
int main(int argc,char** argv) {
    CHECK(argc==2);
    auto bin=std::filesystem::absolute(argv[1]);
    auto config=bin.parent_path()/"test-config";
    std::filesystem::create_directories(config);
    SetEnvironmentVariableW(L"NEWFON_CONFIG_DIR",config.c_str());
    CoInitializeEx(nullptr,COINIT_MULTITHREADED);
    std::wstring registry=L"Software\\NewfonSAPI-Tests-"+std::to_wstring(GetCurrentProcessId());
    try {
        // Defaults, invalid values, UTF-8 Cyrillic, duplicate keys owned by newfon.ini.
        Write(config/"prefs.ini", "[General]\nsample_rate=12000\ninterpolation_multiplier=2\ndec_sep_point=False\nuse_dictionary=3\npause=75\nintonation=60\naccel=3\n[english_pronunciation]\nx=кс\n[symbols]\n€ = евро:1\n@ = собака:0\nѣ = е:1\n");
        auto p=ParamReader::Load();CHECK(p.samples_per_sec==12000 && !p.dec_sep_point && !p.use_rulex && p.use_user_dictionary);
        {CHECK(p.acceleration==3);newfon_conf_t conf{};ParamReader::ApplyToConf(p,conf);CHECK(conf.acceleration==3);}
        CHECK(IniFile(ParamReader::IniPath()).Section(L"english_pronunciation")[L"x"]==L"кс");
        CHECK(ApplyConfiguredSymbols(L"€@",false)==L" евро @");
        CHECK(ApplyConfiguredSymbols(L"@",true)==L" собака ");
        CHECK(ApplyConfiguredSymbols(L"хлѢб",false)==L"хлеб");
        CHECK(ApplyConfiguredSymbols(L"ѣ",true)==L"ѣ");
        Write(config/"ru_dict.dic", "\xef\xbb\xbfслово сло+во\n");
        CHECK(ApplyUserDictionary(L"Слово словом") == L"сло+во словом");
        Write(config/"ru_dict.dic", "");CHECK(ApplyUserDictionary(L"слово")==L"слово");
        Write(config/"prefs.ini", "[General]\nsample_rate=bad\ninterpolation_multiplier=99\nUseLegacyRateAlgo=garbage\naccel=8\n");
        p=ParamReader::Load();CHECK(p.samples_per_sec==10000 && p.use_legacy_rate_algo && p.acceleration==0);
        // Each voice token activates a distinct core voice; no COM server registration needed.
        HMODULE dll=LoadLibraryW((bin/L"newfon_sapi.dll").c_str());CHECK(dll);
        auto getClass=reinterpret_cast<HRESULT (WINAPI*)(REFCLSID,REFIID,void**)>(GetProcAddress(dll,"DllGetClassObject"));CHECK(getClass);
        IClassFactory* factory=nullptr;CHECK(SUCCEEDED(getClass(CLSID_NewfonSapi,IID_IClassFactory,reinterpret_cast<void**>(&factory))));
        std::set<uint64_t> hashes;
        for(DWORD voice: {0,2,1,3}) {
            ISpTTSEngine* engine=nullptr;CHECK(SUCCEEDED(factory->CreateInstance(nullptr,__uuidof(ISpTTSEngine),reinterpret_cast<void**>(&engine))));
            ISpObjectWithToken* withToken=nullptr;CHECK(SUCCEEDED(engine->QueryInterface(__uuidof(ISpObjectWithToken),reinterpret_cast<void**>(&withToken))));
            ISpObjectToken* token=nullptr;CHECK(SUCCEEDED(CoCreateInstance(__uuidof(SpObjectToken),nullptr,CLSCTX_INPROC_SERVER,__uuidof(ISpObjectToken),reinterpret_cast<void**>(&token))));
            CHECK(SUCCEEDED(token->SetId(nullptr,(L"HKEY_CURRENT_USER\\"+registry).c_str(),TRUE)));
            CHECK(SUCCEEDED(token->SetDWORD(L"VoiceIndex",voice)));
            CHECK(SUCCEEDED(withToken->SetObjectToken(token)));
            token->SetDWORD(L"VoiceIndex",99);CHECK(withToken->SetObjectToken(token)==E_INVALIDARG);
            GUID fmt;WAVEFORMATEX* wave=nullptr;CHECK(SUCCEEDED(engine->GetOutputFormat(nullptr,nullptr,&fmt,&wave)));
            // SAPI is handed the format of the original Newfon SAPI: 11025 Hz, 8-bit
            // mono, as the JAWS instructions expect (sapi5x.ini, Output=8).
            CHECK(wave->nSamplesPerSec==11025 && wave->wBitsPerSample==8 && wave->nChannels==1 && wave->nBlockAlign==1);
            std::wstring text=L"Проверка голоса. Привет, мир!";
            SPVTEXTFRAG frag{};frag.State.eAction=SPVA_Speak;frag.State.Volume=100;frag.pTextStart=text.c_str();frag.ulTextLen=static_cast<ULONG>(text.size());
            Site normal;CHECK(SUCCEEDED(engine->Speak(0,fmt,wave,&frag,&normal)));CHECK(normal.audio.size()>1000);hashes.insert(Hash(normal.audio));
            Site fast;fast.rate=8;CHECK(SUCCEEDED(engine->Speak(0,fmt,wave,&frag,&fast)));CHECK(fast.audio.size()<normal.audio.size());
            Site slow;slow.rate=-8;CHECK(SUCCEEDED(engine->Speak(0,fmt,wave,&frag,&slow)));CHECK(slow.audio.size()>normal.audio.size());
            Site stopped;stopped.abort=true;CHECK(SUCCEEDED(engine->Speak(0,fmt,wave,&frag,&stopped)));CHECK(stopped.audio.empty());
            Site midstop;midstop.abortAfter=100;CHECK(SUCCEEDED(engine->Speak(0,fmt,wave,&frag,&midstop)));CHECK(midstop.audio.size()<normal.audio.size());
            // Silence in unsigned 8-bit PCM is 128, not 0.
            Site muted;muted.volume=0;CHECK(SUCCEEDED(engine->Speak(0,fmt,wave,&frag,&muted)));for(uint8_t sample:muted.audio) CHECK(sample==128);
            std::cout<<"voice "<<voice<<": "<<normal.audio.size()<<" bytes, rate and abort OK\n";
            CoTaskMemFree(wave);token->Release();withToken->Release();engine->Release();
        }
        CHECK(hashes.size()==4);
        // Speaks `text` with the given prefs.ini and returns the audio.
        auto say=[&](const std::string& prefs,const std::wstring& text) {
            Write(config/"prefs.ini",prefs);
            ISpTTSEngine* engine=nullptr;CHECK(SUCCEEDED(factory->CreateInstance(nullptr,__uuidof(ISpTTSEngine),reinterpret_cast<void**>(&engine))));
            ISpObjectWithToken* withToken=nullptr;CHECK(SUCCEEDED(engine->QueryInterface(__uuidof(ISpObjectWithToken),reinterpret_cast<void**>(&withToken))));
            ISpObjectToken* token=nullptr;CHECK(SUCCEEDED(CoCreateInstance(__uuidof(SpObjectToken),nullptr,CLSCTX_INPROC_SERVER,__uuidof(ISpObjectToken),reinterpret_cast<void**>(&token))));
            CHECK(SUCCEEDED(token->SetId(nullptr,(L"HKEY_CURRENT_USER\\"+registry).c_str(),TRUE)));
            CHECK(SUCCEEDED(token->SetDWORD(L"VoiceIndex",0)));CHECK(SUCCEEDED(withToken->SetObjectToken(token)));
            GUID fmt;WAVEFORMATEX* wave=nullptr;CHECK(SUCCEEDED(engine->GetOutputFormat(nullptr,nullptr,&fmt,&wave)));
            SPVTEXTFRAG frag{};frag.State.eAction=SPVA_Speak;frag.State.Volume=100;frag.pTextStart=text.c_str();frag.ulTextLen=(ULONG)text.size();
            Site site;CHECK(SUCCEEDED(engine->Speak(0,fmt,wave,&frag,&site)));
            CoTaskMemFree(wave);token->Release();withToken->Release();engine->Release();
            return site.audio;
        };
        {
            // [english_pronunciation] holds Latin combinations, not just single
            // letters, and the longest one wins: "ee" beats "e".
            const std::string base="[General]\nuse_dictionary=0\n";
            auto combined=say(base+"[english_pronunciation]\ne = е\nsh = ш\nee = и\n",L"sheesh");
            auto reference=say(base,L"шиш");
            CHECK(!reference.empty() && combined==reference);
            // A single letter still works, and the combination is not required.
            CHECK(say(base+"[english_pronunciation]\nx = кс\n",L"xy")==say(base,L"ксy"));
            std::cout<<"Latin combinations replaced as a group\n";
        }
        {
            // Bookmarks (NVDA sets one per chunk) meet resampling (10000 Hz core ->
            // 11025 Hz output): flushing the resampler must not drop the audio held
            // back for the events.
            std::wstring first=L"Проверка голоса. ",second=L"Привет, мир!",mark=L"1";
            SPVTEXTFRAG a{},b{},c{};
            a.State.eAction=SPVA_Speak;a.State.Volume=100;a.pTextStart=first.c_str();a.ulTextLen=(ULONG)first.size();a.pNext=&b;
            b.State.eAction=SPVA_Bookmark;b.pTextStart=mark.c_str();b.ulTextLen=(ULONG)mark.size();b.ulTextSrcOffset=(ULONG)first.size();b.pNext=&c;
            c.State.eAction=SPVA_Speak;c.State.Volume=100;c.pTextStart=second.c_str();c.ulTextLen=(ULONG)second.size();c.ulTextSrcOffset=(ULONG)first.size();
            // The same phrase without a bookmark is the reference.
            std::wstring whole=first+second;
            SPVTEXTFRAG plain{};plain.State.eAction=SPVA_Speak;plain.State.Volume=100;plain.pTextStart=whole.c_str();plain.ulTextLen=(ULONG)whole.size();
            size_t lengths[2]{},marked2x=0;
            for(int marked=0;marked<3;++marked) {
                // Third pass: interpolation doubles the output rate, bookmarks stay.
                Write(config/"prefs.ini",marked<2?"[General]\nuse_dictionary=0\n":"[General]\nuse_dictionary=0\ninterpolation_multiplier=2\n");
                ISpTTSEngine* engine=nullptr;CHECK(SUCCEEDED(factory->CreateInstance(nullptr,__uuidof(ISpTTSEngine),reinterpret_cast<void**>(&engine))));
                ISpObjectWithToken* withToken=nullptr;CHECK(SUCCEEDED(engine->QueryInterface(__uuidof(ISpObjectWithToken),reinterpret_cast<void**>(&withToken))));
                ISpObjectToken* token=nullptr;CHECK(SUCCEEDED(CoCreateInstance(__uuidof(SpObjectToken),nullptr,CLSCTX_INPROC_SERVER,__uuidof(ISpObjectToken),reinterpret_cast<void**>(&token))));
                CHECK(SUCCEEDED(token->SetId(nullptr,(L"HKEY_CURRENT_USER\\"+registry).c_str(),TRUE)));
                CHECK(SUCCEEDED(token->SetDWORD(L"VoiceIndex",0)));CHECK(SUCCEEDED(withToken->SetObjectToken(token)));
                GUID fmt;WAVEFORMATEX* wave=nullptr;CHECK(SUCCEEDED(engine->GetOutputFormat(nullptr,nullptr,&fmt,&wave)));
                CHECK(wave->nSamplesPerSec==(marked<2?11025u:22050u) && wave->wBitsPerSample==8);
                Site site;CHECK(SUCCEEDED(engine->Speak(0,fmt,wave,marked?&a:&plain,&site)));
                CHECK(site.bookmarks==(marked?1:0));
                if(marked<2) lengths[marked]=site.audio.size(); else marked2x=site.audio.size();
                CoTaskMemFree(wave);token->Release();withToken->Release();engine->Release();
            }
            CHECK(lengths[0]>1000 && lengths[1]==lengths[0]);
            CHECK(marked2x>lengths[1]*19/10 && marked2x<lengths[1]*21/10);
            std::cout<<"Bookmarked audio survives resampling: "<<lengths[1]<<" -> "<<marked2x<<" bytes with interpolation\n";
        }
        factory->Release();FreeLibrary(dll);
        RulexClient rulex;rulex.EnsureLoaded(bin.wstring());CHECK(rulex.HasRulex());
        auto accented=rulex.ApplyToRussianWords(L"молоко");CHECK(accented!=L"молоко");std::cout<<"Rulex loaded and applied accents\n";
        {
            // Installed layout: one read-only rulex.db above the arch folder, as in Program Files.
            // Own folder per run: a deleted one stays undeletable for a while when
            // something else (an antivirus, say) still holds its files open.
            auto root=bin.parent_path()/("rulex-layout-"+std::to_string(GetCurrentProcessId()));
            auto arch=root/"arch";auto db=root/"rulex.db";
            std::error_code ec;
            std::filesystem::create_directories(arch);
            for(auto name:{"newfon_rulex.dll","rulex.dll"}) std::filesystem::copy_file(bin/name,arch/name);
            std::filesystem::copy_file(bin/"rulex.db",db);CHECK(SetFileAttributesW(db.c_str(),FILE_ATTRIBUTE_READONLY));
            {RulexClient shared;shared.EnsureLoaded(arch.wstring());CHECK(shared.HasRulex());CHECK(shared.ApplyToRussianWords(L"молоко")==accented);}
            SetFileAttributesW(db.c_str(),FILE_ATTRIBUTE_NORMAL);
            std::filesystem::remove_all(root,ec);
            std::cout<<"Rulex opened a shared read-only database\n";
        }
        RegDeleteTreeW(HKEY_CURRENT_USER,registry.c_str());CoUninitialize();
        std::cout<<"All integration checks passed\n";return 0;
    } catch(const std::exception& e) {RegDeleteTreeW(HKEY_CURRENT_USER,registry.c_str());std::cerr<<e.what()<<'\n';CoUninitialize();return 1;}
}
