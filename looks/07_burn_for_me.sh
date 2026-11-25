#!/usr/bin/env bash
# 7 Burn for Me — near-black frame; an orange candle-glow vignette reveals
# the cover. The glow is a static radial mask whose gamma/brightness are
# driven by loudness, so it grows and brightens with RMS (cheap: LUT only).
source "$(dirname "$0")/common.sh"
NUM=07
PREP="scale=$IW:$IW:flags=lanczos,crop=$IW:$IH:0:(ih-$IH)/2,format=gbrp,
  colorchannelmixer=rr=.75:rg=.45:rb=.10:gr=.40:gg=.30:gb=.05:br=.10:bg=.08:bb=.02,
  format=yuv420p"
# mask is made in gray, eq'd by loudness, then copied into all three planes so
# maskedmerge fades chroma to neutral too (YUV black with chroma isn't black).
GRAPH="
color=black:s=${IW}x$IH:r=$FPS:d=1,format=gray,
  geq=lum='255*pow(max(0,1-hypot((X-W/2)/1.2,(Y-H*0.55))/(H*0.85)),2.4)',
  $LOOP,eq@M=gamma=0.6:brightness=0,split[m0][mc];
[mc]scale=$((IW/2)):$((IH/2)):flags=bilinear,split[m1][m2];
[m0][m1][m2]mergeplanes=mapping=0x001020:format=yuv420p[mask];
color=black:s=${IW}x$IH:r=$FPS,format=yuv420p[blk];
[src]eq@L=brightness=0:contrast=1.1:saturation=1.3[img];
[blk][img][mask]maskedmerge,lagfun=decay=0.7[core]"
CMDS=(
  # quiet: a small dim ember; loud: glow swells across the frame
  'eq@M gamma=0.4+1.5*e+(rnd(1)-0.5)*0.1'
  'eq@M brightness=-0.1+0.08*e+(rnd(2)-0.5)*0.04'
  'eq@L brightness=-0.05+0.2*e'
  'eq@L contrast=1.05+0.6*e'
)
render "$@"
