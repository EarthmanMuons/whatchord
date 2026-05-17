# Website Asset Recipes

This directory documents how we create source media for the public website.

## Real-Time Loop

The published loop lives at `docs/site/images/real_time.mp4`.

1. Open the app in the Xcode Simulator.
2. Use the simulator's **Record Screen** function to capture the real-time input
   animation.
3. Open the recording in QuickTime Player.
4. Trim the clip to a seamless loop and export it as `input.mov`.
5. Encode the website asset with `ffmpeg`:

```bash
ffmpeg -i input.mov \
  -c:v libx264 \
  -crf 23 \
  -preset slow \
  -pix_fmt yuv420p \
  -an \
  -vf "scale=-2:1240" \
  -movflags +faststart \
  real_time.mp4
```

Flag notes:

- `-i source.mov`: reads the trimmed QuickTime export.
- `-c:v libx264`: encodes the video as H.264 for broad browser compatibility in
  an MP4 container.
- `-crf 23`: sets constant quality. Lower values improve quality and increase
  file size; higher values reduce file size.
- `-preset slow`: spends more encoding time to improve compression efficiency.
  This is a good fit because the loop is generated manually and does not need to
  encode in real time.
- `-pix_fmt yuv420p`: writes a widely compatible pixel format for browser and
  device playback.
- `-an`: removes audio. The loop is silent, and removing audio avoids extra file
  size and autoplay issues on the web.
- `-vf "scale=-2:1240"`: scales the height to 1240 px and automatically chooses
  an even width that preserves the aspect ratio. This keeps the source roughly
  2x the CSS-rendered feature screenshot size on the website.
- `-movflags +faststart`: moves MP4 metadata to the beginning of the file so the
  browser can begin playback before downloading the whole video.
- `real_time.mp4`: writes the encoded output expected by the site.
