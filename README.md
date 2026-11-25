# Every Cast Shell — music videos

Ten cheap, gritty music videos for *Every Cast Shell* (Jonathan Kendall),
built only from the seashell cover art and plain ffmpeg filtergraphs.

- `looks/NN_*.sh` — one look per song (`--test SECONDS [START]` for a short clip)
- `looks/common.sh` — shared renderer: title card, loudness → `sendcmd`, encode
- `tools/env.py` — per-frame loudness envelope (quiet ≈ 0, explosive ≈ 1)
- `tools/cmds.py` — turns the envelope into an ffmpeg `sendcmd` script
- `render_all.sh` — renders everything to `out/NN-title.mp4`

Inputs (not committed): song WAVs in `~/Downloads` (`SONGS_DIR`), cover PNG
(`COVER_SRC`). Output: 1920x1080, 30 fps, H.264 veryfast CRF 20, AAC 320k.

Speed note: the dynamic chain runs at 1280x720 in YUV and is upscaled at the
end; colour grading happens once on the still before it is looped.
