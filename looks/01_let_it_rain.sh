#!/usr/bin/env bash
# 1 Let It Rain — blue tint, falling rain-streak noise, slow push-in, smear.
# Loudness: brightness/contrast lift, rain opacity, zoom pump, longer smear.
source "$(dirname "$0")/common.sh"
NUM=01
# cover -> IW square, blue monochrome tint (done once)
PREP="scale=$IW:$IW:flags=lanczos,format=gbrp,colorchannelmixer=rr=.18:rg=.22:rb=.06:gr=.26:gg=.32:gb=.08:br=.40:bg=.50:bb=.14,format=yuv420p"

# One frame of sparse noise dots, stretched vertically into streaks, stacked
# twice so a scrolling crop wraps seamlessly. Two layers = two depths.
rain_layer() {  # $1=label $2=rows(streak length = IH/rows) $3=threshold $4=px/frame $5=seed
  echo "color=black:s=$((IW/2))x$2:r=$FPS:d=1,format=gray,noise=c0s=100:c0f=u:all_seed=$5,
  lut=c0='if(gt(val,$3),255,0)',trim=end_frame=1,scale=$IW:$IH:flags=neighbor,
  avgblur=sizeX=1:sizeY=3,split[$1a][$1b];[$1a][$1b]vstack,$LOOP,
  crop=$IW:$IH:0:'$IH-mod(n*$4,$IH)'[$1]"
}
GRAPH="
[src]scale@z=w=$IW:h=$IW:flags=bilinear,crop=$IW:$IH:(iw-$IW)/2:(ih-$IH)/2-$((IH/18)),
  eq@L=brightness=-0.12:contrast=1.0[base];
$(rain_layer rn 40 236 34 7);
$(rain_layer rf 24 240 52 11);
[rn][rf]blend=all_mode=lighten,lagfun=decay=0.6,format=yuv420p[rain];
[base][rain]blend@r=c0_mode=screen:c0_opacity=0.3:c1_mode=normal:c2_mode=normal,
  lagfun@s=decay=0.9,
  vignette=PI/4[core]"
CMDS=(
  # slow push-in over the song (+12%) plus a loudness pump (+6%)
  "scale@z w=2*int($IW*(1+0.12*t/D+0.06*e)/2)"
  "scale@z h=2*int($IW*(1+0.12*t/D+0.06*e)/2)"
  'eq@L brightness=-0.16+0.3*e'
  'eq@L contrast=0.9+0.9*e'
  'blend@r c0_opacity=0.3+0.7*e'
  'lagfun@s decay=0.85+0.12*e'
)
render "$@"
