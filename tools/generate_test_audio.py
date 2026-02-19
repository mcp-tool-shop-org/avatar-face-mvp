#!/usr/bin/env python3
"""Generate a test WAV file that sweeps through vowel-like frequency bands.

Creates a ~5 second audio file that cycles through the frequency ranges
corresponding to each viseme (ou, oh, aa, ih, ee), making it easy to verify
that the FFT-based viseme driver correctly maps audio to mouth shapes.

Output: assets/audio/test_vowels.wav (16-bit PCM, 44100 Hz, mono)
"""

import struct
import math
import os

SAMPLE_RATE = 44100
DURATION_PER_VOWEL = 0.8  # seconds per vowel sound
PAUSE_DURATION = 0.2  # silence between vowels
AMPLITUDE = 0.5

# Center frequencies for each viseme band (matches config/tuning.json)
VOWEL_FREQS = [
    ("ou", 375.0),   # 250-500 Hz center
    ("oh", 625.0),   # 500-750 Hz center
    ("aa", 900.0),   # 700-1100 Hz center
    ("ih", 1650.0),  # 1400-1900 Hz center
    ("ee", 2250.0),  # 1900-2600 Hz center
]

def generate_tone(freq: float, duration: float, fade_ms: float = 30.0) -> list[float]:
    """Generate a sine tone with fade in/out."""
    samples = []
    num_samples = int(SAMPLE_RATE * duration)
    fade_samples = int(SAMPLE_RATE * fade_ms / 1000.0)

    for i in range(num_samples):
        t = i / SAMPLE_RATE
        val = AMPLITUDE * math.sin(2 * math.pi * freq * t)

        # Add a harmonic for more natural vowel-like sound
        val += AMPLITUDE * 0.3 * math.sin(2 * math.pi * freq * 2.1 * t)
        val += AMPLITUDE * 0.1 * math.sin(2 * math.pi * freq * 3.05 * t)

        # Fade envelope
        if i < fade_samples:
            val *= i / fade_samples
        elif i > num_samples - fade_samples:
            val *= (num_samples - i) / fade_samples

        samples.append(val)
    return samples


def generate_silence(duration: float) -> list[float]:
    return [0.0] * int(SAMPLE_RATE * duration)


def write_wav(filename: str, samples: list[float]):
    """Write 16-bit mono WAV file."""
    num_samples = len(samples)
    data_size = num_samples * 2  # 16-bit = 2 bytes per sample
    file_size = 36 + data_size

    with open(filename, "wb") as f:
        # RIFF header
        f.write(b"RIFF")
        f.write(struct.pack("<I", file_size))
        f.write(b"WAVE")

        # fmt chunk
        f.write(b"fmt ")
        f.write(struct.pack("<I", 16))       # chunk size
        f.write(struct.pack("<H", 1))        # PCM format
        f.write(struct.pack("<H", 1))        # mono
        f.write(struct.pack("<I", SAMPLE_RATE))
        f.write(struct.pack("<I", SAMPLE_RATE * 2))  # byte rate
        f.write(struct.pack("<H", 2))        # block align
        f.write(struct.pack("<H", 16))       # bits per sample

        # data chunk
        f.write(b"data")
        f.write(struct.pack("<I", data_size))
        for s in samples:
            clamped = max(-1.0, min(1.0, s))
            f.write(struct.pack("<h", int(clamped * 32767)))


def main():
    all_samples: list[float] = []

    # Lead-in silence
    all_samples.extend(generate_silence(0.3))

    # Cycle through each vowel twice
    for _cycle in range(2):
        for name, freq in VOWEL_FREQS:
            print(f"  {name}: {freq:.0f} Hz")
            all_samples.extend(generate_tone(freq, DURATION_PER_VOWEL))
            all_samples.extend(generate_silence(PAUSE_DURATION))

    # Trailing silence
    all_samples.extend(generate_silence(0.3))

    total_duration = len(all_samples) / SAMPLE_RATE
    print(f"Total duration: {total_duration:.1f}s ({len(all_samples)} samples)")

    out_dir = os.path.join(os.path.dirname(os.path.dirname(__file__)), "assets", "audio")
    os.makedirs(out_dir, exist_ok=True)
    out_path = os.path.join(out_dir, "test_vowels.wav")
    write_wav(out_path, all_samples)
    print(f"Written: {out_path}")


if __name__ == "__main__":
    main()
