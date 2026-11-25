#!/usr/bin/env bash
# 5 Lemons, Bread and Candles — warm sepia, paper-grain overlay, gentle
# handheld wobble.
# Loudness: wobble amplitude, warmth/brightness, candle flicker.
source "$(dirname "$0")/common.sh"
NUM=05
PW=$((IW+80)); PH=$((IH+50))
PREP="scale=$PW:$PW:flags=lanczos,crop=$PW:$PH:0:(ih-$PH)/2,format=gbrp,
  hue=s=0,colorchannelmixer=rr=.95:rg=.0:rb=.0:gr=.0:gg=.72:gb=.0:br=.0:bg=.0:bb=.45,
  eq=gamma=1.15:contrast=0.85:brightness=0.03,format=yuv420p"
# paper: fine fibre noise + big soft blotches, generated once and looped
GRAPH="
color=c=0x808080:s=${IW}x$IH:r=$FPS:d=1,format=yuv420p,noise=c0s=70:c0f=u:all_seed=5,
  gblur=sigma=1.2:sigmaV=0.4,trim=end_frame=1[fib];
color=c=0x808080:s=48x27:r=$FPS:d=1,format=yuv420p,noise=c0s=90:c0f=u:all_seed=9,
  scale=$IW:$IH:flags=bicubic,gblur=sigma=12,trim=end_frame=1[blot];
[fib][blot]blend=c0_mode=grainmerge:c1_mode=normal:c2_mode=normal,$LOOP[paper];
[src]crop@w=$IW:$IH:40:25,eq@L=brightness=-0.08:contrast=1.0:saturation=1.0[img];
[img][paper]blend=c0_mode=overlay:c0_opacity=0.75:c1_mode=normal:c2_mode=normal,
  vignette=PI/3.6[core]"
CMDS=(
  'crop@w x=40+int(wob(1)*(6+30*e))'
  'crop@w y=25+int(wob(2)*(4+20*e))'
  'eq@L brightness=-0.12+0.22*e+(rnd(3)-0.5)*0.05*(0.3+e)'
  'eq@L contrast=0.85+0.45*e'
  'eq@L saturation=0.85+0.8*e'
)
render "$@"
