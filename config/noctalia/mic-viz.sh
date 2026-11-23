#!/usr/bin/env bash
# Mic spectrum for the bar: cava reads the default PipeWire source, one line of ▁..█ per frame.
# Noctalia's own visualizer only listens to the output. Silent frames print a space, which hides the widget.
set -euo pipefail
cfg="${XDG_RUNTIME_DIR:-/tmp}/noctalia-mic-viz.cava"
cat >"$cfg" <<EOF
[general]
bars = ${MIC_VIZ_BARS:-12}
framerate = ${MIC_VIZ_FPS:-20}
[input]
method = pipewire
source = $(pactl get-default-source)
[output]
method = raw
raw_target = /dev/stdout
data_format = ascii
ascii_max_range = 7
EOF
exec cava -p "$cfg" | awk -F';' 'BEGIN { split("▁ ▂ ▃ ▄ ▅ ▆ ▇ █", b, " ") }
{ s = ""; loud = 0
  for (i = 1; i < NF; i++) { s = s b[$i + 1]; if ($i > 0) loud = 1 }
  print (loud ? s : " "); fflush() }'
