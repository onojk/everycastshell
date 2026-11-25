#!/usr/bin/env bash
# Render every look in order (10 last: it samples the finished videos 1-9).
#   ./render_all.sh                 all songs, full length
#   ./render_all.sh 03 07           just those songs
#   ./render_all.sh --test 20 [start] [NN...]   short test clips
set -euo pipefail
cd "$(dirname "$0")"
args=()
if [[ ${1:-} == --test ]]; then args=(--test "${2:-20}" "${3:-0}"); shift $(( $# >= 3 ? 3 : $# )); fi
nums=("$@"); [[ ${#nums[@]} -gt 0 ]] || nums=(01 02 03 04 05 06 07 08 09 10)
for n in "${nums[@]}"; do
  script=$(ls looks/"$n"_*.sh 2>/dev/null | head -1) || true
  if [[ -z $script ]]; then echo "!! no look for $n, skipping"; continue; fi
  "$script" "${args[@]}"
done
