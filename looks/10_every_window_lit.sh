#!/usr/bin/env bash
# 10 Every Window Lit — 3x3 grid of short loops from looks 1-9 (windows of a
# building at night). Windows start dark and "light up" one by one across the
# song; the last one lights exactly when the final chorus hits, then all nine
# burn together.
# Needs the full renders out/01..09 (render_all.sh renders 10 last). Each tile
# loops the loudest 6 s of its song (after the title card).
# Loudness: lit windows brighten/contrast with it; dark windows faintly flicker.
IW=1920; IH=1080     # tiles are 640x360 — build the grid at full size
source "$(dirname "$0")/common.sh"
NUM=10
TW=$((IW/3)); TH=$((IH/3)); FW=8   # tile size, window-frame thickness

# final chorus = start of the last sustained loud stretch (5 s-smoothed
# loudness > 0.4 for >= 10 s)
ensure_env 10
TF=$(python3 - "$ROOT/work/10.env" <<'PY'
import sys, numpy as np
d = np.loadtxt(sys.argv[1]); e = d[:, 1]; fps = 30
k = np.convolve(e, np.ones(150) / 150, "same") > 0.4
runs, i = [], 0
while i < len(k):
    if k[i]:
        j = i
        while j < len(k) and k[j]: j += 1
        if j - i >= 10 * fps: runs.append(i)
        i = j
    else: i += 1
print(round(d[runs[-1], 0], 2) if runs else round(d[-1, 0] * 0.8, 2))
PY
)
echo ">> final chorus detected at ${TF}s"

# cut one looping clip per earlier song
EXTRA_INPUTS=()
for i in 1 2 3 4 5 6 7 8 9; do
  n=0$i; src=$(ls "$ROOT"/out/$n-*.mp4 2>/dev/null | head -1 || true)
  [[ -n $src ]] || { echo "!! need out/$n-*.mp4 (render looks 1-9 first)"; exit 1; }
  ensure_env "$n"
  tile="$ROOT/work/tile$n.mp4"
  if [[ ! -f $tile || $tile -ot $src ]]; then
    st=$(python3 -c "
import numpy as np
d=np.loadtxt('$ROOT/work/$n.env'); e=d[:,1]; k=180
m=np.convolve(e,np.ones(k)/k,'valid'); m[:300]=-1
print(d[int(np.argmax(m)),0])")
    ffmpeg -v error -y -ss "$st" -t 6 -i "$src" -an \
      -vf "scale=$((TW-2*FW)):$((TH-2*FW)),pad=$TW:$TH:$FW:$FW:black" \
      -c:v libx264 -preset veryfast -crf 18 "$tile"
  fi
  EXTRA_INPUTS+=(-stream_loop -1 -i "$tile")
done

# windows light in a scattered order, not reading order
ORDER=(4 0 8 2 6 1 7 3 5)
PREP="scale=16:16"
GRAPH="[src]nullsink;"
CMDS=()
for k in 0 1 2 3 4 5 6 7 8; do
  pos=${ORDER[$k]}
  # the cover branch is discarded, so drive sendcmd from a tile instead
  send=""; [[ $pos == 0 ]] && send="sendcmd=f=$ROOT/work/10.cmd,"
  GRAPH+="[$((pos+2)):v]setpts=N/$FPS/TB,${send}eq@w$pos=brightness=-0.3:contrast=0.7:saturation=0.15[t$pos];"
  # lit fraction L ramps 0->1 over 1.5 s at T_k = TF*(k+1)/9
  L="clip((t-$TF*($k+1)/9)/1.5,0,1)"
  CMDS+=("eq@w$pos brightness=(1-$L)*(-0.36+0.03*rnd($pos))+$L*(-0.06+0.14*e)"
         "eq@w$pos contrast=(1-$L)*0.65+$L*(0.95+0.5*e)"
         "eq@w$pos saturation=(1-$L)*0.12+$L*(0.85+0.4*e)")
done
GRAPH+="[t0][t1][t2][t3][t4][t5][t6][t7][t8]xstack=inputs=9:layout=0_0|w0_0|w0+w1_0|0_h0|w0_h0|w0+w1_h0|0_h0+h3|w0_h0+h3|w0+w1_h0+h3,
  vignette=PI/5[core]"
render "$@"
