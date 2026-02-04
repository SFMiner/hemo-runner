# Placeholder for Sound Assets

This directory should contain the following audio files:

## Required Sounds

1. **heartbeat.ogg** or **heartbeat.wav**
   - Rhythmic heartbeat pulse
   - Used during heart zone transitions

2. **whoosh.ogg** or **whoosh.wav**
   - Ambient fluid flow sound
   - Background audio during gameplay

3. **exchange.ogg** or **exchange.wav**
   - "Squish" sound effect
   - Plays when O₂/CO₂ exchange occurs

4. **stuck.ogg** or **stuck.wav**
   - Alert/warning sound
   - Plays when player collides with platelet

## Audio Format Recommendations

- **OGG Vorbis** (.ogg) - Best for Godot, good compression, looping support
- **WAV** (.wav) - Uncompressed, good for short sound effects
- Avoid MP3 for gameplay sounds (licensing issues, poor looping)

## Volume Guidelines

- Keep all audio normalized to similar levels
- Background music/ambience: -6dB to -12dB
- Sound effects: 0dB to -3dB
