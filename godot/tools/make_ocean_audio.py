"""Original deterministic sound design. No external recordings or samples.
Run with Python, NumPy and SciPy to rebuild the v0.23 WAV assets.
"""
from pathlib import Path
import wave
import numpy as np
from scipy.signal import butter, sosfilt

RATE = 22050
OUT = Path(__file__).resolve().parents[1] / 'assets' / 'audio-v023'
OUT.mkdir(parents=True, exist_ok=True)
RNG = np.random.default_rng(23023)

def write(name, samples, peak=.62):
    samples = np.asarray(samples)
    samples -= samples.mean(axis=0)
    if not name.startswith('ambience_'):
        ramp = np.ones(len(samples))
        first = min(round(.004*RATE),len(samples)//4)
        last = min(round(.035*RATE),len(samples)//4)
        ramp[:first] = np.sin(np.linspace(0,np.pi/2,first))**2
        ramp[-last:] = np.sin(np.linspace(np.pi/2,0,last))**2
        samples *= ramp if samples.ndim == 1 else ramp[:,None]
    samples *= peak / max(.001, np.max(np.abs(samples)))
    with wave.open(str(OUT / (name + '.wav')), 'wb') as f:
        f.setnchannels(1 if samples.ndim == 1 else samples.shape[1])
        f.setsampwidth(2); f.setframerate(RATE)
        f.writeframes(np.asarray(samples * 32767, dtype='<i2').tobytes())

def bell(freq, duration=.7):
    t = np.arange(round(duration * RATE)) / RATE
    attack = 1 - np.exp(-t * 180)
    return attack * (np.sin(2*np.pi*freq*t)*np.exp(-t*7)
                     + .22*np.sin(2*np.pi*freq*2.01*t)*np.exp(-t*12))

def phrase(notes, spacing=.13, tail=.8):
    audio = np.zeros(round((spacing*len(notes)+tail)*RATE))
    for i, note in enumerate(notes):
        voice = bell(note, tail); start = round(i*spacing*RATE)
        audio[start:start+len(voice)] += voice
    return audio

def water(duration, low=220, high=1700):
    t = np.arange(round(duration*RATE)) / RATE
    noise = RNG.normal(0, 1, len(t))
    noise = sosfilt(butter(2, [low, high], fs=RATE, btype='bandpass', output='sos'), noise)
    envelope = np.sin(np.pi*t/duration)**2 * np.exp(-t*2/duration)
    return noise * envelope

write('pearl', phrase([880, 1174.66], .065, .42))
write('treasure', phrase([523.25, 659.25, 783.99, 1046.5], .10, .9))
write('heart', phrase([659.25, 880], .12, .7))
write('checkpoint', phrase([392, 523.25, 659.25], .12, .85))
write('victory', phrase([523.25, 659.25, 783.99, 1046.5, 1318.51], .15, 1.1))
write('boss_defeat', phrase([392, 523.25, 659.25, 783.99, 1046.5], .10, 1.0))
write('ui', bell(740, .18))
write('boost', water(.48, 130, 2400))
write('splash', water(.65, 250, 3200))
write('swim', water(.24, 200, 1100))
write('impact', water(.28, 80, 1100) + bell(185,.28)*.22)
write('boss_hit', water(.40, 100, 1600) + phrase([440,659.25], .04,.32)[:round(.40*RATE)]*.25)
t = np.arange(round(.28*RATE))/RATE
phase = 2*np.pi*np.cumsum(700*np.exp(-t*6)+220)/RATE
write('bubble', np.sin(phase)*(1-np.exp(-t*100))*np.exp(-t*18))

# Periodic FFT filtering gives genuinely seamless stereo ambience loops.
for name, cutoff, bubbles in [('reef',650,16), ('deep',240,7), ('waterfall',2100,4)]:
    duration = 16; n = RATE*duration; t = np.arange(n)/RATE
    channels = []
    for ch in range(2):
        spectrum = np.fft.rfft(RNG.normal(0,1,n))
        freq = np.fft.rfftfreq(n,1/RATE)
        spectrum *= (freq/(freq+45)) / (1+(freq/cutoff)**3)
        channel = np.fft.irfft(spectrum,n)
        channel *= .72 + .18*np.sin(2*np.pi*t/duration*3+ch)
        for i in range(bubbles):
            voice = bell(float(RNG.uniform(240,520)),.36)*.035
            start = int(RNG.integers(n))
            np.add.at(channel,(np.arange(len(voice))+start)%n,voice)
        channels.append(channel)
    write('ambience_'+name,np.column_stack(channels),.38)
print('Built 13 original effects and three seamless stereo ambience loops.')
