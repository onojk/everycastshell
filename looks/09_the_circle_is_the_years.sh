#!/usr/bin/env bash
# 9 The Circle Is the Years — circular crop of the cover, gold tint, slow
# continuous rotation, black outside the circle.
# Loudness: rotation speed (integrates loudness), brightness/contrast/sat.
source "$(dirname "$0")/common.sh"
NUM=09
C=$(( IH*92/100 /2*2 ))      # circle diameter
S=$(( C*142/100 /2*2 ))      # source square so rotation never shows corners
PREP="scale=$S:$S:flags=lanczos,format=gbrp,
  colorchannelmixer=rr=.70:rg=.45:rb=.10:gr=.55:gg=.40:gb=.08:br=.20:bg=.15:bb=.05,
  format=yuv420p"
GRAPH="
color=black:s=${C}x$C:r=$FPS:d=1,format=gray,
  geq=lum='255*clip(($C/2-1-hypot(X-$C/2,Y-$C/2))/1.5,0,1)',$LOOP[mask];
[src]rotate@r=a=0:ow=$C:oh=$C:c=black:bilinear=1,
  eq@L=brightness=-0.05:contrast=1.0:saturation=1.0,format=yuva420p[disc];
[disc][mask]alphamerge[discA];
color=black:s=${IW}x$IH:r=$FPS,format=yuv420p[bg];
[bg][discA]overlay=(W-w)/2:(H-h)/2:shortest=0,lagfun@s=decay=0.8[core]"
CMDS=(
  'rotate@r a=-(0.03*t+0.35*E)'
  'eq@L brightness=-0.12+0.24*e'
  'eq@L contrast=0.95+0.6*e'
  'eq@L saturation=0.8+0.8*e'
  'lagfun@s decay=0.7+0.25*e'
)
render "$@"
