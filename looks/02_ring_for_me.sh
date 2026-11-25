#!/usr/bin/env bash
# 2 Ring for Me — B&W, irregular brightness flicker, thin white showwaves
# "phone line" across the middle.
# Loudness: brightness/contrast, flicker depth, occasional dropouts; the line
# itself is the waveform (flat in quiet verses, violent in choruses).
source "$(dirname "$0")/common.sh"
NUM=02
PREP="scale=$IW:$IW:flags=lanczos,crop=$IW:$IH:0:(ih-$IH)/2,format=yuv420p,hue=s=0"
GRAPH="
[1:a]asplit[aout][aw];
[aw]showwaves=s=${IW}x$((IH/3)):mode=p2p:rate=$FPS:colors=white:draw=full,format=yuva420p[line];
[src]eq@L=brightness=-0.15:contrast=1.1[bw];
[bw][line]overlay=0:(H-h)/2,vignette=PI/4.5[core]"
CMDS=(
  # base level follows loudness; irregular flicker scales with it;
  # ~3% of frames drop out dark, more often when loud
  'eq@L brightness=-0.22+0.28*e+(rnd(1)-0.5)*(0.03+0.22*e)-(0.25 if rnd(2)>0.985-0.05*e else 0)'
  'eq@L contrast=1.0+0.9*e'
)
render "$@"
