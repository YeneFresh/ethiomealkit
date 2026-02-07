# Orbital Stems Visualizer

A real-time audio visualization tool that creates spinning spectrum rings for individual audio stems, with optional MIDI control for Ableton Live integration.

## Features

- **Drag & Drop Audio Loading**: Drop multiple audio files to create stems
- **Real-time Spectrum Visualization**: Each stem gets its own spinning frequency ring
- **Interactive Planet Control**: Drag planets to adjust orbit radius and angle
- **Web MIDI Integration**: Send CC messages to Ableton Live for parameter control
- **Audio Controls**: Play/stop all stems with individual gain control
- **Stereo Panning**: Automatic stereo positioning based on orbital angle

## MIDI Mapping

For each stem `i`, the following MIDI CC messages are sent:
- **Angle**: CC (20 + i) - Current orbital angle [0-127]
- **Radius**: CC (30 + i) - Distance from center [0-127] 
- **Speed**: CC (40 + i) - Rotation speed [0-127]

## Setup for Ableton Integration

1. **Windows**: Install [loopMIDI](https://www.tobias-erichsen.de/software/loopmidi.html) to create virtual MIDI ports
2. **macOS**: Enable IAC Driver in Audio MIDI Setup
3. **Linux**: Use JACK or ALSA loopback

## Usage

1. Start the app: `npm run dev`
2. Load audio stems by dragging files onto the canvas or using "Add Stems"
3. Click "Play" to start all stems
4. Drag the colored planets to adjust their orbital position
5. Use sliders in the sidebar for fine control
6. Enable "Send MIDI" and select your virtual MIDI port
7. In Ableton Live, map the CC messages to parameters you want to control

## Development

```bash
npm install    # Install dependencies
npm run dev    # Start development server
npm run build  # Build for production
```

Built with React, Web Audio API, Web MIDI API, and Tailwind CSS.