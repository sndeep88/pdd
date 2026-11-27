"""Synthesises the notification sounds (royalty-free, generated from scratch).

Outputs 16-bit mono WAV files to:
  assets/sounds/            (in-app playback)
  android/app/src/main/res/raw/  (Android notification channel sounds)

Run: py tool/make_sounds.py
"""
import math
import os
import random
import struct
import wave

SR = 44100
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
random.seed(7)


def silence(seconds):
    return [0.0] * int(SR * seconds)


def mix_at(buf, tone, start):
    s = int(start * SR)
    end = s + len(tone)
    if end > len(buf):
        buf.extend([0.0] * (end - len(buf)))
    for i, v in enumerate(tone):
        buf[s + i] += v


def metal_tone(freq, length, partials, tau, gain=1.0, attack=0.002):
    """Struck-metal tone: inharmonic partials with exponential decay."""
    n = int(SR * length)
    out = [0.0] * n
    for ratio, amp, t_scale in partials:
        f = freq * ratio
        if f > SR / 2.2:
            continue
        w = 2 * math.pi * f / SR
        for i in range(n):
            t = i / SR
            env = math.exp(-t / (tau * t_scale))
            if t < attack:
                env *= t / attack
            out[i] += amp * env * math.sin(w * i)
    return [v * gain for v in out]


def click(length=0.012, gain=0.5):
    """Tiny noise burst for the 'clink' attack."""
    n = int(SR * length)
    prev = 0.0
    out = []
    for i in range(n):
        x = random.uniform(-1, 1)
        hp = x - prev * 0.9  # crude high-pass
        prev = x
        out.append(hp * math.exp(-i / (n * 0.25)) * gain)
    return out


COIN_PARTIALS = [(1.0, 1.0, 1.0), (2.76, 0.5, 0.7), (5.4, 0.25, 0.5), (8.93, 0.12, 0.35)]


def coins():
    buf = silence(0.1)
    # three quick coin "clinks" rising in pitch, then falling ticks and a bright ka-ching.
    for start, f, g in [(0.00, 1318.5, 0.85), (0.09, 1760.0, 0.85), (0.19, 2093.0, 0.9)]:
        mix_at(buf, metal_tone(f, 0.55, COIN_PARTIALS, 0.16, g), start)
        mix_at(buf, click(), start)
    for start, f, g in [(0.37, 2637.0, 0.45), (0.43, 2349.0, 0.4), (0.48, 2794.0, 0.4)]:
        mix_at(buf, metal_tone(f, 0.25, COIN_PARTIALS, 0.07, g), start)
        mix_at(buf, click(0.008, 0.35), start)
    # final shimmering ka-ching (two partials of a coin ring)
    mix_at(buf, metal_tone(1975.5, 0.9, COIN_PARTIALS, 0.3, 0.9), 0.56)
    mix_at(buf, metal_tone(2637.0, 0.9, COIN_PARTIALS, 0.34, 0.7), 0.58)
    mix_at(buf, click(0.014, 0.5), 0.56)
    return buf


def bell():
    ratios = [(0.56, 0.7, 1.4), (0.92, 0.6, 1.2), (1.19, 0.55, 1.0), (1.71, 0.5, 0.8),
              (2.0, 0.9, 1.0), (2.74, 0.4, 0.6), (3.0, 0.35, 0.55), (3.76, 0.25, 0.4)]
    buf = silence(0.02)
    mix_at(buf, metal_tone(784.0, 1.9, ratios, 0.55, 0.9), 0.0)
    mix_at(buf, click(0.01, 0.3), 0.0)
    return buf


def success():
    buf = silence(0.02)
    notes = [523.25, 659.25, 783.99, 1046.5]
    partials = [(1.0, 1.0, 1.0), (2.0, 0.35, 0.7), (3.0, 0.15, 0.5)]
    for i, f in enumerate(notes):
        mix_at(buf, metal_tone(f, 0.7, partials, 0.22, 0.8), i * 0.11)
    mix_at(buf, metal_tone(1568.0, 1.0, partials, 0.4, 0.55), 0.36)
    return buf


def finish(buf):
    # fade-out tail to avoid clicks, normalise to -2 dBFS
    fade = int(SR * 0.03)
    for i in range(fade):
        buf[-1 - i] *= i / fade
    peak = max(abs(v) for v in buf) or 1.0
    scale = 0.79 / peak
    return [max(-1.0, min(1.0, v * scale)) for v in buf]


def write_wav(path, samples):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with wave.open(path, 'wb') as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(b''.join(struct.pack('<h', int(v * 32767)) for v in samples))


def main():
    sounds = {'coins': coins(), 'bell': bell(), 'success': success()}
    targets = [
        os.path.join(ROOT, 'assets', 'sounds'),
        os.path.join(ROOT, 'android', 'app', 'src', 'main', 'res', 'raw'),
    ]
    for name, buf in sounds.items():
        data = finish(buf)
        for folder in targets:
            path = os.path.join(folder, name + '.wav')
            write_wav(path, data)
        print(f'{name}.wav  {len(data) / SR:.2f}s')


if __name__ == '__main__':
    main()
