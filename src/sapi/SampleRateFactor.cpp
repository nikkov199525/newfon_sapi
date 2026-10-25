#include "SampleRateFactor.h"

#include <cmath>

namespace {
constexpr double kPi = 3.14159265358979323846;

// Частота среза фильтра восстановления -- фиксированная, от частоты
// дискретизации не зависит.
constexpr double kCutoffHz = 6000.0;

// 1/(2Q) секций фильтра Баттерворта 8-го порядка: sin((2k-1)·π/16), в том же
// порядке, в каком секции идут в Nefonit.
constexpr double kSectionDamping[] = {
    0.9807852843222002,
    0.8314696173059154,
    0.5555702326496501,
    0.19509032179250105,
};

// Компенсация громкости после вставки нулей: в Nefonit выход множителя 1
// масштабируется на 32767, множителя 2 -- на 61824.528..., множителя 4 --
// на 123184.210...
constexpr double kFactor2Gain = 61824.52830188679 / 32767.0;
constexpr double kFactor4Gain = 123184.21052631579 / 32767.0;
}  // namespace

int SampleRateFactorInterpolator::NormalizeFactor(int factor) {
    return factor == 2 || factor == 4 ? factor : 1;
}

SampleRateFactorInterpolator::SampleRateFactorInterpolator(int sampleRate, int factor)
    : m_factor(NormalizeFactor(factor)),
      m_outputSampleRate(sampleRate * m_factor) {
    if (!active()) return;
    m_gain = m_factor == 2 ? kFactor2Gain : kFactor4Gain;

    const double omega = 2.0 * kPi * kCutoffHz / static_cast<double>(m_outputSampleRate);
    const double cosOmega = std::cos(omega);
    const double sinOmega = std::sin(omega);
    for (int i = 0; i < kSectionCount; ++i) {
        const double alpha = sinOmega * kSectionDamping[i];
        const double a0 = 1.0 + alpha;
        Biquad& section = m_sections[i];
        section.b0 = (1.0 - cosOmega) * 0.5 / a0;
        section.b1 = (1.0 - cosOmega) / a0;
        section.b2 = section.b0;
        section.a1 = 2.0 * cosOmega / a0;
        section.a2 = -(1.0 - alpha) / a0;
    }
}

double SampleRateFactorInterpolator::Biquad::Run(double x) {
    const double w = x + a1 * w1 + a2 * w2;
    const double y = b0 * w + b1 * w1 + b2 * w2;
    w2 = w1;
    w1 = w;
    return y;
}

void SampleRateFactorInterpolator::Process(const float* input, size_t count, std::vector<float>& output) {
    output.clear();
    if (!active()) {
        output.assign(input, input + count);
        return;
    }
    output.reserve(count * static_cast<size_t>(m_factor));
    for (size_t i = 0; i < count; ++i) {
        for (int phase = 0; phase < m_factor; ++phase) {
            double value = phase == 0 ? static_cast<double>(input[i]) : 0.0;
            for (Biquad& section : m_sections) value = section.Run(value);
            output.push_back(static_cast<float>(value * m_gain));
        }
    }
}
