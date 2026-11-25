#!/usr/bin/env bash
# 6 Carry Us Home — city-night teal/orange, the cover scrolls sideways
# through a streaked horizontal motion blur; hard strobe flashes / black cuts
# on loud transients.
# Loudness: scroll speed (integrates loudness), blur length, flashes.
source "$(dirname "$0")/common.sh"
NUM=06
P=$((IH*2))   # period of the mirrored strip A|flip(A)
PREP="scale=$IH:$IH:flags=lanczos,format=gbrp,
  hue=s=0,eq=contrast=1.3,
  colorbalance=rs=-0.5:gs=0.25:bs=0.3:rm=0.05:gm=-0.05:bm=-0.1:rh=0.45:gh=0.05:bh=-0.4,
  eq=saturation=1.6,format=yuv420p,
  split[a][b];[b]hflip[bf];[a][bf]hstack,split[s1][s2];[s1][s2]hstack"
GRAPH="
[src]crop@x=$IW:$IH:0:0,avgblur@b=sizeX=2:sizeY=1,lagfun@s=decay=0.85,
  eq@S=brightness=-0.1:contrast=1.0,vignette=PI/4[core]"
CMDS=(
  "crop@x x=int(10*t+220*E)%$P"
  'avgblur@b sizeX=int(1+36*e)'
  'lagfun@s decay=0.8+0.17*e'
  # strobe: strong hits flash white, some get a black cut instead
  "eq@S brightness=(0.75 if rnd(1)>0.35 else -1.0) if (h>0.3 and e>0.35) else -0.14+0.24*e"
  "eq@S contrast=(2.0 if (h>0.3 and e>0.35) else 0.95+0.8*e)"
)
render "$@"
