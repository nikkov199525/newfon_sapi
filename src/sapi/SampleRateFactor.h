#pragma once

#include <cstddef>
#include <vector>

// Интерполяция «Sample rate factor» в том виде, как она устроена в Nefonit TTS
// (перенесена из rutts-android): частота умножается на 2 или 4, между исходными
// отсчётами вставляются нули, а полученный сигнал проходит через фильтр нижних
// частот Баттерворта 8-го порядка со срезом 6000 Гц (четыре биквада, прямая
// форма II) с компенсацией громкости. При множителе 1 сигнал не трогается.
class SampleRateFactorInterpolator {
public:
    // 2 и 4 -- как есть, любое другое значение -- 1.
    static int NormalizeFactor(int factor);

    SampleRateFactorInterpolator(int sampleRate, int factor);

    int factor() const { return m_factor; }
    int outputSampleRate() const { return m_outputSampleRate; }
    bool active() const { return m_factor > 1; }

    // Записывает в output factor() отсчётов на каждый входной (float, [-1, 1]).
    // Состояние фильтра сохраняется между вызовами: звук фразы непрерывен.
    void Process(const float* input, size_t count, std::vector<float>& output);

private:
    struct Biquad {
        double b0 = 0.0, b1 = 0.0, b2 = 0.0;
        double a1 = 0.0, a2 = 0.0;
        double w1 = 0.0, w2 = 0.0;

        double Run(double x);
    };

    static constexpr int kSectionCount = 4;

    int m_factor;
    int m_outputSampleRate;
    double m_gain = 1.0;
    Biquad m_sections[kSectionCount];
};
