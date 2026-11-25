#!/usr/bin/env bash
# Shared plumbing for every look. A look script sets:
#   NUM    two-digit song number
#   PREP   static filter chain applied ONCE to the cover (before looping).
#          Do RGB colour work here and end in yuv420p: the dynamic chain
#          should stay YUV (eq/lagfun/noise/blend) — auto RGB<->YUV
#          conversions per frame are the main speed killer.
#   GRAPH  dynamic filtergraph: reads [src] (looped, sendcmd-driven cover) and
#          optionally [1:a]; must output [core] at IWxIH (upscaled to 1920x1080 after). If it consumes
#          [1:a] it must also output [aout].
#   CMDS   array of 'filter@name cmd=EXPR' specs for tools/cmds.py (e, h, t, D)
#   GRAIN  (optional) film grain strength, default 18, 0 = off. Grain is
#          rendered at 640x360 and upscaled (chunky, filmic, cheap to encode)
#          and merged into luma after [core] — looks should NOT add noise.
#   EXTRA_INPUTS (optional array of extra ffmpeg input args, inputs 2..)
# then calls `render "$@"`.
# Usage of any look:  looks/NN_x.sh            full song
#                     looks/NN_x.sh --test 20 [start]   short test clip
set -euo pipefail
ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
SONGS_DIR=${SONGS_DIR:-$HOME/Downloads}
COVER_SRC=${COVER_SRC:-$HOME/Downloads/conical_seashell_by_onojk123_dc4bjh2.png}
FONT=${FONT:-/usr/share/fonts/opentype/urw-base35/NimbusMonoPS-Regular.otf}
COVER="$ROOT/assets/cover_2160.png"
W=1920; H=1080; FPS=30
# Internal working size for the dynamic chain (upscaled to WxH at the end:
# faster, and the soft upscale is part of the grit). Override with IW/IH env.
IW=${IW:-1280}; IH=${IH:-720}
CRF=${CRF:-24}
ARTIST_LINE="Every Cast Shell — Jonathan Kendall"
mkdir -p "$ROOT/work" "$ROOT/out" "$ROOT/assets"

title_of() {
  case $1 in
    01) echo "Let It Rain";;            02) echo "Ring for Me";;
    03) echo "The Light Is On";;        04) echo "Laundry in the Sea";;
    05) echo "Lemons, Bread and Candles";; 06) echo "Carry Us Home";;
    07) echo "Burn for Me";;            08) echo "Grey and Gentle Wings";;
    09) echo "The Circle Is the Years";; 10) echo "Every Window Lit";;
  esac
}
slug_of() { title_of "$1" | tr 'A-Z' 'a-z' | sed 's/[^a-z0-9]\+/-/g; s/^-//; s/-$//'; }

ensure_cover() {
  [[ -f $COVER ]] || ffmpeg -v error -y -i "$COVER_SRC" \
    -vf "scale=2160:2160:flags=lanczos,format=rgb24" "$COVER"
}
ensure_env() {  # $1=NUM
  local wav="$SONGS_DIR/$(title_of "$1").wav"
  [[ -f "$ROOT/work/$1.env" && "$ROOT/work/$1.env" -nt "$wav" ]] || \
    python3 "$ROOT/tools/env.py" "$wav" "$ROOT/work/$1.env" "$FPS"
}
song_dur() { ffprobe -v error -show_entries format=duration -of csv=p=0 "$SONGS_DIR/$(title_of "$1").wav"; }

# Loop filter: decode/prepare the still once, repeat it forever at FPS.
LOOP="loop=loop=-1:size=1:start=0,setpts=N/$FPS/TB"

render() {
  local dur="" start=0 tag=""
  if [[ ${1:-} == --test ]]; then dur=${2:-20}; start=${3:-0}; tag="test-"; fi
  ensure_cover; ensure_env "$NUM"
  local title wav out cmdf graphf
  title=$(title_of "$NUM"); wav="$SONGS_DIR/$title.wav"
  [[ -n $dur ]] || dur=$(song_dur "$NUM")
  out="$ROOT/out/${tag}${NUM}-$(slug_of "$NUM").mp4"
  cmdf="$ROOT/work/$NUM.cmd"; graphf="$ROOT/work/$NUM.graph"
  printf '%s' "$title" > "$ROOT/work/$NUM.title.txt"
  printf '%s' "$ARTIST_LINE" > "$ROOT/work/artist.txt"

  CMD_START=$start python3 "$ROOT/tools/cmds.py" "$ROOT/work/$NUM.env" "$cmdf" "${CMDS[@]}"

  local fade="alpha='if(lt(t,3),1,max(0,4-t))':enable='lt(t,4)'"
  {
    printf '[0:v]%s%s,sendcmd=f=%s[src];\n' "${PREP:+$PREP,}" "$LOOP" "$cmdf"
    printf '%s;\n' "$GRAPH"
    if (( ${GRAIN:-18} > 0 )); then
      printf 'nullsrc=s=640x360:r=%s,format=yuv420p,lutyuv=y=128:u=128:v=128,noise=c0s=%s:c0f=t+u,scale=%s:%s:flags=bicubic[grain];\n' \
        "$FPS" "${GRAIN:-18}" "$IW" "$IH"
      printf '[core]format=yuv420p[cg];[cg][grain]blend=c0_mode=grainmerge:c1_mode=normal:c2_mode=normal[core2];\n'
    else
      printf '[core]format=yuv420p[core2];\n'
    fi
    printf "[core2]scale=%s:%s:flags=bicubic," "$W" "$H"
    printf "drawtext=fontfile=%s:textfile=%s:fontsize=76:fontcolor=white:shadowcolor=black@0.7:shadowx=3:shadowy=3:x=(w-tw)/2:y=h/2-90:%s," \
      "$FONT" "$ROOT/work/$NUM.title.txt" "$fade"
    printf "drawtext=fontfile=%s:textfile=%s:fontsize=34:fontcolor=white@0.85:shadowcolor=black@0.7:shadowx=2:shadowy=2:x=(w-tw)/2:y=h/2+20:%s," \
      "$FONT" "$ROOT/work/artist.txt" "$fade"
    printf 'fps=%s[vout]\n' "$FPS"
  } > "$graphf"

  local amap=(-map 1:a)
  grep -q '\[aout\]' <<<"$GRAPH" && amap=(-map '[aout]')
  echo ">> $out  (${dur}s from ${start}s)"
  local t0=$SECONDS
  ffmpeg -hide_banner -v error -stats_period 10 -stats -y \
    -i "$COVER" -ss "$start" -i "$wav" "${EXTRA_INPUTS[@]}" \
    -filter_threads "$(nproc)" -/filter_complex "$graphf" -map '[vout]' "${amap[@]}" \
    -t "$dur" -r "$FPS" -c:v libx264 -preset veryfast -crf "$CRF" -pix_fmt yuv420p \
    -c:a aac -b:a 320k -movflags +faststart "$out"
  echo ">> done in $((SECONDS - t0))s"
}
EXTRA_INPUTS=()
