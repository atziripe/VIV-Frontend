# Welcome hero video

Put the file at **`assets/video/welcome.mp4`** (exactly that name). It's
bundled through the `assets/video/` entry in `pubspec.yaml`; no code change.

Without the file, with Reduce Motion on, or while it loads, the hero shows the
still photo tone with the glow, as before.

## How it plays
- Muted, looping, starts on its own, fades in over ~0.6 s.
- Mixed with other audio: it never stops the user's music or podcast.
- Cropped to fill the hero (like `object-fit: cover`), so keep the subject
  near the centre.
- A soft dark gradient sits under the "VIV" wordmark at the top-left, and the
  wordmark turns light over the video.

## File spec
| | |
|---|---|
| Format | MP4, H.264 (High profile), `yuv420p` |
| Orientation | Vertical, 9:16 (e.g. 1080×1920; 720×1280 is plenty) |
| Length | 6–12 s, first and last frame matching for a seamless loop |
| Audio | None (strip the track) |
| Size | Aim for ≤ 4 MB; it ships inside the app |
| Content | No baked-in text or logo; keep the top-left calm for the wordmark |

## Export with ffmpeg
```sh
ffmpeg -i source.mov -an -vf "scale=720:-2,fps=30" \
  -c:v libx264 -profile:v high -pix_fmt yuv420p -crf 26 -preset slow \
  -movflags +faststart assets/video/welcome.mp4
```
Raise `-crf` (e.g. 28) for a smaller file, lower it (e.g. 23) for more detail.
