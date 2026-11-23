#!/usr/bin/env python3
"""Darkvoid dim-light: derive light colours from darkvoid by one rule, so every app stays consistent.

  darkvoid-light.py                     print the named palette as JSON
  darkvoid-light.py '#83b7ad' ...       print dark -> light for each colour
  darkvoid-light.py --file IN OUT       copy IN to OUT with every #rrggbb[aa] converted
  darkvoid-light.py --test              self-check

Rule (see themes/README.md):
  - background is warm paper, never white; surfaces (near-bg greys) sit darker than the paper
  - greys keep darkvoid's order and ratios: contrast against the bg is remapped by RAMP
  - colours keep their hue, chroma is capped (no neon) and their brightness order (3.3:1 .. 6:1, lighter than text)
  - colour tints near the bg (diff / search backgrounds) become pale tints of the same hue
"""
import json, math, re, sys

def _s2l(x): return x / 12.92 if x <= 0.04045 else ((x + 0.055) / 1.055) ** 2.4
def _l2s(x): return 12.92 * x if x <= 0.0031308 else 1.055 * x ** (1 / 2.4) - 0.055
def _rgb(h): h = h.lstrip('#'); return [int(h[i:i + 2], 16) / 255 for i in (0, 2, 4)]
def lum(h): r, g, b = [_s2l(c) for c in _rgb(h)]; return .2126 * r + .7152 * g + .0722 * b
def contrast(a, b): a, b = sorted([lum(a), lum(b)], reverse=True); return (a + .05) / (b + .05)

def oklch(h):
    r, g, b = [_s2l(c) for c in _rgb(h)]
    l = (.4122214708 * r + .5363325363 * g + .0514459929 * b) ** (1 / 3)
    m = (.2119034982 * r + .6806995451 * g + .1073969566 * b) ** (1 / 3)
    s = (.0883024619 * r + .2817188376 * g + .6299787005 * b) ** (1 / 3)
    L = .2104542553 * l + .7936177850 * m - .0040720468 * s
    A = 1.9779984951 * l - 2.4285922050 * m + .4505937099 * s
    B = .0259040371 * l + .7827717662 * m - .8086757660 * s
    return L, math.hypot(A, B), math.degrees(math.atan2(B, A)) % 360

def from_oklch(L, C, H):
    A, B = C * math.cos(math.radians(H)), C * math.sin(math.radians(H))
    l = (L + .3963377774 * A + .2158037573 * B) ** 3
    m = (L - .1055613458 * A - .0638541728 * B) ** 3
    s = (L - .0894841775 * A - 1.2914855480 * B) ** 3
    rgb = [4.0767416621 * l - 3.3077115913 * m + .2309699292 * s,
           -1.2684380046 * l + 2.6097574011 * m - .3413193965 * s,
           -.0041960863 * l - .7034186147 * m + 1.7076147010 * s]
    return '#' + ''.join(f'{round(min(1, max(0, _l2s(c))) * 255):02x}' for c in rgb)

DARK_BG = '#1c1c1c'
WARM = (0.008, 70)              # warm neutral paper: no blue glare, not grey, not yellow
BG = from_oklch(0.855, *WARM)    # paper: well below white, light enough for a full contrast ladder
CMAX = 0.13                     # chroma cap for text colours: ink, never neon (dark inks carry more chroma calmly)
TINT_CMAX = 0.04                # chroma cap for tinted backgrounds
# grey ramp: dark contrast -> light contrast (darkvoid comment 2.4, fg 9.4, keyword 15.1)
RAMP = [(1.0, 1.0), (1.64, 1.75), (2.4, 3.0), (9.37, 7.6), (15.1, 12.2), (21.0, 13.0)]  # keyword/text 1.6x, as in darkvoid

def _ramp(c):
    for (x0, y0), (x1, y1) in zip(RAMP, RAMP[1:]):
        if c <= x1: return y0 + (c - x0) / (x1 - x0) * (y1 - y0)
    return RAMP[-1][1]

def _darker(C, H, target):
    """Colour with chroma C, hue H, darker than BG, at contrast `target` against it."""
    lo, hi = 0.0, oklch(BG)[0]
    for _ in range(40):
        mid = (lo + hi) / 2
        lo, hi = (mid, hi) if contrast(from_oklch(mid, C, H), BG) > target else (lo, mid)
    return from_oklch(lo, C, H)

def to_light(h):
    h = h.lower()
    if h == '#000000': return h                     # shadows stay shadows
    _, C, H = oklch(h)
    c = contrast(h, DARK_BG)
    if c < 1.03: return BG
    if C < 0.015:                                    # grey
        if c < 1.45: return _darker(*WARM, c)       # surface: recessed below the paper
        return _darker(*WARM, _ramp(c))
    if c < 2.5: return _darker(min(C, TINT_CMAX), H, min(1.12 + (c - 1) * .3, 1.5))  # tinted background
    # text colours keep darkvoid's brightness order (3:1 .. 17:1 -> 3.3:1 .. 6:1) but stay well lighter than body
    # text (7.6:1): a pastel turned into near-black ink loses its hue and reads as plain text.
    # Soft pastels get a chroma floor so their hue still shows on paper; greyish colours (C < 0.035) stay grey.
    Cout = min(C + 0.03 if C >= 0.035 else C, CMAX)  # keeps pastel < saturated order
    return _darker(Cout, H, 3.3 + (min(c, 17) - 3) / 14 * 2.7 if c >= 3 else _ramp(c))

# focus (niri ring, herdr/kitty active pane): in dark the sage is the brightest thing on screen; on paper a dark
# ink doesn't catch the eye, the most saturated mid-tone does. Unfocused borders go faint (selection level).
FOCUS = _darker(0.14, oklch('#83b7ad')[2], 3.2)
FAINT = None  # set below, after to_light

HEX = re.compile(r'#([0-9a-fA-F]{6})([0-9a-fA-F]{2})?\b')
def convert_text(s): return HEX.sub(lambda m: to_light('#' + m[1]) + (m[2] or ''), s)

FAINT = to_light('#303030')

# darkvoid roles (themes/darkvoid.md plus the house UI colours) -> light
DARK = dict(bg='#1c1c1c', bg_alt='#161616', surface='#252525', visual='#303030', eob='#3c3c3c',
            line_nr='#404040', border='#585858', comment='#585858', inactive='#858585',
            type='#a1a1a1', identifier='#b1b1b1', fg='#c0c0c0', type_builtin='#c5c5c5',
            string='#d1d1d1', func='#e1e1e1', bracket='#e6e6e6', kw='#f1f1f1',
            cursor='#bdfe58', operator='#1bfd9c', accent='#83b7ad', bool='#66b2b2',
            constant='#b2d8d8', preprocessor='#6a7a8a', info='#7fa1c3', hint='#bedc74',
            warning='#f2c879', error='#ff7b72', added='#baffc9', changed='#ffffba', removed='#ffb3ba',
            green='#8cc9a0', magenta='#a8a0b0',
            diff_added_bg='#1f2a24', diff_removed_bg='#2a2020', diff_added_word='#3b5a45',
            diff_removed_word='#5a3b3b')

def _dist(a, b):
    (l1, c1, h1), (l2, c2, h2) = oklch(a), oklch(b)
    a1, b1 = c1 * math.cos(math.radians(h1)), c1 * math.sin(math.radians(h1))
    a2, b2 = c2 * math.cos(math.radians(h2)), c2 * math.sin(math.radians(h2))
    return math.dist((l1, a1, b1), (l2, a2, b2))

def test():
    assert to_light(DARK_BG) == BG and lum(BG) < 0.65, 'bg must stay below white glare'
    order = [to_light(DARK[k]) for k in ('comment', 'type', 'fg', 'string', 'func', 'kw')]
    cs = [contrast(x, BG) for x in order]
    assert cs == sorted(cs), f'grey ramp order broken: {cs}'
    for k in ('accent', 'operator', 'error', 'added', 'warning', 'info'):
        x = to_light(DARK[k]); assert .06 <= oklch(x)[1] <= CMAX + .004 and contrast(x, BG) >= 3.25, (k, x)
    acc = [to_light(DARK[k]) for k in ('operator', 'bool', 'constant', 'info', 'warning', 'error', 'hint')]  # preprocessor vs info are near in darkvoid too
    import itertools
    near = [(a, b) for a, b in itertools.combinations(acc, 2) if _dist(a, b) < 0.03]  # bool vs constant share darkvoid's teal; lightness alone separates them
    assert not near, f'accents too close: {near}'
    assert contrast(to_light(DARK['fg']), BG) > 7.2
    assert convert_text('a: #1c1c1c80;') == f'a: {BG}80;'
    print('ok')

if __name__ == '__main__':
    a = sys.argv[1:]
    if a[:1] == ['--test']: test()
    elif a[:1] == ['--file']: open(a[2], 'w').write(convert_text(open(a[1]).read()))
    elif a: print('\n'.join(f'{x} -> {to_light(x)}' for x in a))
    else: print(json.dumps({k: to_light(v) for k, v in DARK.items()}, indent=1))
