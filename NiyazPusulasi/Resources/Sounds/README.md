# Adhan Sound Files

This directory contains adhan (call to prayer) audio files for notification sounds.

## Required Files

The following `.caf` files need to be added to this directory:

1. **turkey_adhan.caf** - Turkey/Istanbul classic adhan
2. **mecca_adhan.caf** - Mecca/Saudi Arabian style adhan
3. **morocco_adhan.caf** - Morocco/Maghribi style adhan
4. **generic_adhan.caf** - Universal/generic adhan

## Audio Specifications

All sound files must meet iOS notification sound requirements:

- **Format:** Core Audio Format (CAF)
- **Codec:** PCM (Linear PCM) or IMA4 (ADPCM)
- **Sample Rate:** 44.1 kHz (recommended) or 48 kHz
- **Bit Depth:** 16-bit
- **Channels:** Mono (recommended for smaller file size) or Stereo
- **Duration:** Maximum 30 seconds (iOS notification limit)
- **File Size:** Target <2 MB per file (ideally <1 MB)

## How to Convert Audio Files

### Using FFmpeg (Windows/Mac/Linux):

```bash
# Basic conversion (30 seconds, mono, 44.1kHz)
ffmpeg -i input.mp3 -t 30 -ar 44100 -ac 1 -f caf -acodec pcm_s16le output.caf

# With IMA4 compression for smaller file size
ffmpeg -i input.mp3 -t 30 -ar 44100 -ac 1 -f caf -acodec adpcm_ima_wav output.caf
```

### Using afconvert (macOS only):

```bash
# Convert to CAF format
afconvert -f caff -d LEI16@44100 -c 1 input.mp3 output.caf

# With duration limit
afconvert -f caff -d LEI16@44100 -c 1 -t 0 30 input.mp3 output.caf
```

## Source Files

See `AUDIO_SOURCES.md` in the project root for:
- Download URLs for licensed adhan recordings
- License information (CC BY 4.0, CC0)
- Attribution requirements
- Step-by-step download and processing instructions

## Adding Files to Xcode

After converting files to CAF format:

1. Drag all `.caf` files into this `Sounds` directory in Xcode
2. Check "Copy items if needed"
3. Select target: **NiyazPusulasi** (main app)
4. Verify in Build Phases > Copy Bundle Resources that all sounds are included

## Testing

⚠️ **Important:** Notification sounds do NOT play in the iOS Simulator. You must test on a **real device**.

To test:
1. Build and run on a physical iPhone
2. Go to Settings > Notification Sound
3. Select each sound and tap the play button to preview
4. Schedule a test notification to verify it plays at notification time

## Legal Notes

All sound files must have appropriate licenses for commercial use:
- ✅ CC BY 4.0 (requires attribution)
- ✅ CC0 (public domain, no attribution required)
- ❌ CC BY-NC (non-commercial only - NOT allowed)

See `AUDIO_SOURCES.md` for full licensing details and attribution text.

## Current Status

- [ ] turkey_adhan.caf - **TO BE ADDED**
- [ ] mecca_adhan.caf - **TO BE ADDED** (⚠️ needs licensed alternative)
- [ ] morocco_adhan.caf - **TO BE ADDED**
- [ ] generic_adhan.caf - **TO BE ADDED**

Once files are added, check the boxes above and remove this README or update it accordingly.
