#!/usr/bin/env bash
# 3 The Light Is On — sickly fluorescent green, scanlines, VHS chroma bleed,
# tracking jitter, burned-in "03:00 AM" bottom-left.
# Loudness: brightness/contrast, fluorescent flicker, chroma shift, jitter.
source "$(dirname "$0")/common.sh"
NUM=03
printf '03:00 AM' > "$ROOT/work/03.stamp.txt"
STAMPFONT=/usr/share/fonts/truetype/dejavu/DejaVuSansMono-Bold.ttf
PW=$((IW+32)); PH=$((IH+16))
PREP="scale=$PW:$PW:flags=lanczos,crop=$PW:$PH:0:(ih-$PH)/2,format=gbrp,
  colorchannelmixer=rr=.45:rg=.35:rb=.0:gr=.30:gg=.75:gb=.10:br=.15:bg=.35:bb=.25,
  eq=gamma_g=1.15:gamma_r=0.9,format=yuv420p"
GRAPH="
color=black:s=${IW}x$IH:r=$FPS:d=1,format=yuv420p,
  geq=lum='if(lt(mod(Y,3),1),70,255)':cb=128:cr=128,$LOOP[scan];
[src]crop@j=$IW:$IH:16:8,eq@L=brightness=-0.1:contrast=1.0:saturation=1.2,
  drawtext=fontfile=$STAMPFONT:textfile=$ROOT/work/03.stamp.txt:fontsize=$((IH/16)):fontcolor=white@0.9:shadowcolor=black@0.6:shadowx=2:shadowy=2:x=$((IW/22)):y=h-$((IH/7)),
  avgblur=sizeX=5:sizeY=1:planes=6,chromashift@c=cbh=4:crh=-4[img];
[img][scan]blend=c0_mode=multiply:c1_mode=normal:c2_mode=normal,vignette=PI/4.2[core]"
CMDS=(
  'crop@j x=16+int((rnd(1)-0.5)*(2+30*e*(rnd(3)>0.7)))'
  'crop@j y=8+int((rnd(2)-0.5)*(1+10*e*(rnd(4)>0.85)))'
  'eq@L brightness=-0.14+0.24*e+(rnd(5)-0.5)*(0.02+0.12*e)'
  'eq@L contrast=0.95+0.8*e'
  'chromashift@c cbh=int(3+14*e)'
  'chromashift@c crh=-int(3+14*e)'
)
render "$@"
