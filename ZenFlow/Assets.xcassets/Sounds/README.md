# Ambient Sounds for ZenFlow

This directory contains ambient sound files used for meditation sessions in ZenFlow.

## Current Sounds

### 🌧️ Rain (Rain.wav)
- **Category:** Water
- **Description:** Calming rain sounds for peaceful meditation
- **Size:** ~14 MB

### 🌲 Forest (forest.wav)
- **Category:** Nature
- **Description:** Peaceful nature sounds from the forest
- **Size:** ~83 MB

### 🌊 Ocean (ocean.wav)
- **Category:** Water
- **Description:** Relaxing ocean wave sounds
- **Size:** ~82 MB

## Adding New Sounds

To add new ambient sounds to ZenFlow:

1. **Prepare the audio file:**
   - Format: WAV (recommended) or MP3
   - Sample rate: 44.1 kHz or 48 kHz
   - Bit depth: 16-bit or 24-bit
   - Duration: At least 60 seconds (seamless loops recommended)

2. **Add to Assets:**
   - Drag and drop your `.wav` file into this `Sounds` directory in Xcode
   - The file will be automatically added as a dataset

3. **Update the code:**
   - Add the sound to `AmbientSound.allSounds` in `Models/AmbientSound.swift`
   - Specify the correct category (nature, water, or atmosphere)

## Free Sound Resources

Here are some excellent sources for free, high-quality ambient sounds:

### 🎵 Recommended Websites

#### 1. **Freesound.org**
- URL: https://freesound.org
- License: Various Creative Commons licenses
- Content: Huge collection of user-uploaded sounds
- Search tips: Use keywords like "rain loop", "forest ambience", "ocean waves"
- Requirements: Free account required for downloads

#### 2. **Pixabay Sound Effects**
- URL: https://pixabay.com/sound-effects/
- License: Pixabay License (free for commercial use)
- Content: High-quality sound effects and ambient sounds
- Search tips: Filter by "Nature" or "Ambience"
- Requirements: No attribution required

#### 3. **Mixkit Free Sound Effects**
- URL: https://mixkit.co/free-sound-effects/
- License: Mixkit License (free for commercial use)
- Content: Curated collection of professional sounds
- Categories: Nature, Rain, Ocean, Forest, etc.
- Requirements: No attribution required

#### 4. **BBC Sound Effects**
- URL: https://sound-effects.bbcrewind.co.uk/
- License: RemArc License (free for personal/educational use)
- Content: Professional BBC sound archive
- Note: Check license terms for commercial use

#### 5. **Free To Use Sounds**
- URL: https://freetousesounds.com/
- License: Public Domain
- Content: Nature sounds, white noise, ambience
- Requirements: No attribution required

### 🎧 Search Keywords

When searching for ambient sounds, try these keywords:
- Rain: "gentle rain", "thunderstorm", "rain on window", "heavy rain"
- Forest: "forest ambience", "birds chirping", "wind through trees", "woodland"
- Ocean: "ocean waves", "beach waves", "sea ambience", "coastal sounds"
- Other: "wind chimes", "crackling fire", "mountain stream", "night ambience"

### 📝 License Considerations

Always check the license before using sounds:
- **CC0 / Public Domain:** Free to use, no attribution required
- **CC BY:** Free to use, attribution required
- **CC BY-SA:** Free to use, attribution + share-alike
- **CC BY-NC:** Free for non-commercial use only

For commercial use of ZenFlow, prefer:
- Public Domain (CC0)
- Creative Commons CC BY
- Pixabay License
- Mixkit License

### 🎨 Creating Seamless Loops

For the best meditation experience, sounds should loop seamlessly:

1. Use audio editing software (Audacity, Adobe Audition, etc.)
2. Find a section of audio where the beginning and end have similar amplitude
3. Apply crossfade at the loop point
4. Test the loop multiple times to ensure smoothness
5. Export as WAV (44.1 kHz, 16-bit)

### 💡 Tips for Quality

- **Duration:** Longer loops (2-5 minutes) feel more natural
- **Volume:** Normalize audio to -3dB to -6dB (leaves headroom)
- **Stereo:** Use stereo files for immersive experience
- **Compression:** WAV files are preferred for quality, but can be large
- **Testing:** Listen on different devices (phone speaker, headphones, etc.)

## Technical Specifications

### Current Audio Configuration
- **Audio Session Category:** `.ambient`
- **Mix with Others:** Enabled
- **Loops:** Infinite (`numberOfLoops = -1`)
- **Volume Range:** 0.0 to 1.0
- **Fade Duration:** 2-3 seconds (configurable)
- **Max Simultaneous Sounds:** 2 layers

### Supported Formats
- WAV (recommended for quality)
- MP3 (smaller file size)
- M4A/AAC (iOS native)

## Attribution

If using sounds that require attribution, add them here:

<!-- Example:
- "Forest Ambience" by [Author Name] from Freesound.org (CC BY 4.0)
- "Ocean Waves" from Pixabay (Pixabay License)
-->

---

**Last Updated:** November 22, 2025
**Maintained by:** ZenFlow Development Team
