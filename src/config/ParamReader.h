#pragma once
#include <string>
#include "newfon_core.h"
enum class UnicodeNormalizationForm { NFC, NFKC, NFD, NFKD };
enum class InterpolationAlgorithm { Linear, ZeroOrderHold };
// The bridge hands SAPI the format of the original Newfon SAPI: 11025 Hz, 8-bit
// mono (see the JAWS section of docs/Russian.html). Interpolation multiplies it.
constexpr int kSapiBaseOutputRate=11025;
constexpr int kSapiOutputBits=8;
struct NewfonParams {
    bool use_rulex=true;
    bool use_user_dictionary=true;
    bool use_legacy_rate_algo=true;
    // Rate of the synthesized audio; the engine resamples it to what SAPI gets.
    int samples_per_sec=10000;
    int interpolation_multiplier=1;
    InterpolationAlgorithm interpolation_algorithm=InterpolationAlgorithm::Linear;
    static constexpr int wave_buffer_size=1024;
    int silence_at_begin=0, silence_at_end=0;
    // What SAPI is handed: the base rate times the interpolation multiplier.
    int output_sample_rate=0;
    int pause=-1, intonation=50;
    int acceleration=NEWFON_ACCEL_OFF;
    bool dec_sep_point=true, dec_sep_comma=true;
    bool use_unicode_normalization=false;
    UnicodeNormalizationForm unicode_normalization_form=UnicodeNormalizationForm::NFC;
};
class ParamReader {
public:
    static NewfonParams Load();
    static void ApplyToConf(const NewfonParams&,newfon_conf_t&);
    static std::wstring IniPath();
    static std::wstring PrefsPath();
    static std::wstring DictionaryPath();
};

