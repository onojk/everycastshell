#!/usr/bin/env bash
# 8 Grey and Gentle Wings — grey 16mm: heavy grain, dust + scratches,
# gate weave, slow pan across the cover, projector flicker.
# (noise on mid-grey spans ~79..177; >176 keeps ~1% as specks/scratch lines)
# Loudness: contrast/brightness, weave amplitude, dust density.
source "$(dirname "$0")/common.sh"
NUM=08
GRAIN=34
S=$(( IW*14/10 /2*2 ))
PREP="scale=$S:$S:flags=lanczos,format=yuv420p,hue=s=0,eq=gamma=1.1"
GRAPH="
color=0x808080:s=$((IW/10))x$((IH/10)):r=$FPS,format=gray,noise=c0s=100:c0f=t+u,
  lut=c0='if(gt(val,176),255,0)',scale=$IW:$IH:flags=neighbor,gblur=sigma=2.5[dust];
color=0x808080:s=$((IW/2))x1:r=$FPS,format=gray,noise=c0s=100:c0f=t+u,
  lut=c0='if(gt(val,176),170,0)',scale=$IW:$IH:flags=neighbor[scr];
[dust][scr]blend=all_mode=lighten,format=yuv420p[marks];
[src]crop@p=$IW:$IH:0:0,eq@L=brightness=-0.05:contrast=1.0[img];
[img][marks]blend@d=c0_mode=screen:c0_opacity=0.6:c1_mode=normal:c2_mode=normal,
  vignette=PI/3.8[core]"
CMDS=(
  # slow diagonal pan over the song + gate weave (jittery, bigger when loud)
  "crop@p x=int(($S-$IW)*(0.15+0.7*t/D)+(rnd(1)-0.5)*(2+8*e))"
  "crop@p y=int(($S-$IH)*(0.3+0.3*t/D)+(rnd(2)-0.5)*(3+14*e))"
  'eq@L brightness=-0.1+0.15*e+(rnd(3)-0.5)*0.06'
  'eq@L contrast=0.9+0.8*e'
  'blend@d c0_opacity=0.35+0.65*e'
)
render "$@"
