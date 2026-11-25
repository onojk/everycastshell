#!/usr/bin/env bash
# 4 Laundry in the Sea — 4-way mirror kaleidoscope of the cover, slow
# rotation about the centre, warm laundromat tint.
# Loudness: spin speed (angle integrates loudness), brightness/contrast/sat.
source "$(dirname "$0")/common.sh"
NUM=04
QW=$((IW/2)); QH=$((IH/2))
S=$(( (IW*115/100) /2*2 ))   # source square big enough to rotate under the window
PREP="scale=$S:$S:flags=lanczos,format=gbrp,
  colorchannelmixer=rr=.80:rg=.30:rb=.05:gr=.45:gg=.55:gb=.10:br=.15:bg=.30:bb=.30,
  format=yuv420p"
GRAPH="
[src]rotate@r=a=0:ow=$IW:oh=$IH:c=black:bilinear=1,crop=$QW:$QH:0:0,
  eq@L=brightness=-0.1:contrast=1.0:saturation=1.0,split=4[q0][q1][q2][q3];
[q1]hflip[q1f];[q2]vflip[q2f];[q3]hflip,vflip[q3f];
[q0][q1f]hstack[top];[q2f][q3f]hstack[bot];[top][bot]vstack,
  lagfun@s=decay=0.8,vignette=PI/4[core]"
CMDS=(
  'rotate@r a=0.035*t+0.55*E'
  'eq@L brightness=-0.12+0.25*e'
  'eq@L contrast=0.95+0.65*e'
  'eq@L saturation=0.8+0.7*e'
  'lagfun@s decay=0.75+0.2*e'
)
render "$@"
