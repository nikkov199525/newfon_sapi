#pragma once
#include <string>
#include "newfon_core.h"
enum class UnicodeNormalizationForm { NFC, NFKC, NFD, NFKD };
enum class InterpolationAlgorithm { Linear, ZeroOrderHold };
// The bridge hands SAPI 11025 Hz mono, the rate of the original Newfon SAPI (see
// the JAWS section of docs/Russian.html); interpolation multiplies it. The core
// rate is a separate setting -- the speed of the tape, so to say; it defaults to
// the output rate, and then nothing is resampled.
// Samples go out as 16 bit although the core is 8 bit: volume is applied before
// they leave, and at 35% only some 90 of the 256 steps of an 8-bit stream would
// remain, which is audible as hiss. A host may still ask for 8 bit.
constexpr int kSapiBaseOutputRate=11025;
constexpr int kSapiOutputBits=16;
constexpr int kSapiDefaultRate=kSapiBaseOutputRate;
struct NewfonParams {
    bool use_rulex=true;
    bool use_user_dictionary=true;
    bool use_legacy_rate_algo=true;
    // Rate of the synthesized audio, and the rate SAPI is told about.
    int samples_per_sec=kSapiDefaultRate;
    int interpolation_multiplier=1;
    InterpolationAlgorithm interpolation_algorithm=InterpolationAlgorithm::Linear;
    static constexpr int wave_buffer_size=1024;
    int silence_at_begin=0, silence_at_end=0;
    // What SAPI is handed: the core rate times the interpolation multiplier.
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

