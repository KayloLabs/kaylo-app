#!/usr/bin/env python3
"""Builds the app's small sound effects into assets/ (needs numpy).

    python3 apps/customer/tool/make_sounds.py

Everything is synthesised here, so there is no recording to license: a
thumb-piano tine for the notes, a small bell for the chimes. Output is
44.1 kHz mono 16-bit WAV, kept quiet (peak about 0.4 of full scale).
success.wav predates this script and is left alone.
"""
import pathlib
import wave

import numpy as np

SR = 44100
OUT = pathlib.Path(__file__).resolve().parent.parent / "assets"

# A thumb-piano tine: strong fundamental, an octave, a short bright overtone.
TINE = [(1.0, 1.0, 0.26), (2.0, 0.26, 0.13), (5.4, 0.10, 0.035)]
# A small bell: slightly inharmonic upper partials that fade before the hum.
BELL = [(1.0, 1.0, 0.55), (2.0, 0.42, 0.34), (2.76, 0.20, 0.22), (5.4, 0.07, 0.10)]


def tone(freq, dur, partials, attack=0.004):
    """Sum of decaying sine partials, each (ratio, level, decay seconds)."""
    t = np.arange(int(SR * dur)) / SR
    y = np.zeros_like(t)
    for ratio, level, decay in partials:
        y += level * np.sin(2 * np.pi * freq * ratio * t) * np.exp(-t / decay)
    return y * np.minimum(1.0, t / attack)


def pluck(freq, dur=0.5):
    y = tone(freq, dur, TINE)
    n = int(SR * 0.004)
    click = np.random.default_rng(7).standard_normal(n) * np.linspace(1, 0, n)
    y[:n] += 0.05 * click
    return y


def place(buf, y, at):
    i = int(at * SR)
    n = min(len(y), len(buf) - i)
    buf[i : i + n] += y[:n]


def save(name, y, peak, tail=0.03):
    n = int(SR * tail)
    y[-n:] *= np.linspace(1, 0, n) ** 2
    y = y / np.max(np.abs(y)) * peak
    pcm = np.round(np.clip(y, -1, 1) * 32767).astype("<i2")
    with wave.open(str(OUT / name), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(pcm.tobytes())
    print(f"{name}: {len(y) / SR:.2f}s")


# Five notes of a pentatonic scale, one per tap on the logo.
for i, f in enumerate([523.25, 587.33, 659.25, 783.99, 880.00], start=1):
    save(f"note_{i}.wav", pluck(f), 0.42)

# The logo arriving: two bell notes a fifth apart over a soft low hum,
# with a faint echo.
buf = np.zeros(int(SR * 1.5))
place(buf, tone(659.25, 1.4, BELL), 0.00)
place(buf, 0.9 * tone(987.77, 1.2, BELL), 0.17)
place(buf, 0.28 * tone(329.63, 1.4, [(1.0, 1.0, 0.7)], attack=0.03), 0.00)
echo = np.zeros_like(buf)
d = int(SR * 0.19)
echo[d:] = buf[:-d] * 0.22
save("logo_chime.wav", buf + echo, 0.40, tail=0.12)

# A coupon being stamped: a soft thud, then a bright two-note shop bell.
buf = np.zeros(int(SR * 0.62))
t = np.arange(int(SR * 0.09)) / SR
thud = np.sin(2 * np.pi * (150 * t - 330 * t**2)) * np.exp(-t / 0.028)
place(buf, 0.75 * thud, 0.0)
place(buf, 0.8 * tone(783.99, 0.5, BELL[:3]), 0.035)
place(buf, 0.8 * tone(1046.50, 0.45, BELL[:3]), 0.125)
save("coupon.wav", buf, 0.42, tail=0.06)

# A scratch reward opening: a quick rising run of tines.
buf = np.zeros(int(SR * 0.95))
for k, f in enumerate([523.25, 659.25, 783.99, 1046.50, 1318.51]):
    place(buf, (0.75 + 0.06 * k) * pluck(f, 0.6), 0.058 * k)
place(buf, 0.18 * tone(2093.0, 0.5, [(1.0, 1.0, 0.18)]), 0.058 * 4)
save("reveal.wav", buf, 0.42, tail=0.08)
