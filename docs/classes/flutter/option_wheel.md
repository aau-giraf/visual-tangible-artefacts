# OptionWheel

**File:** `Frontend/vta_app/lib/src/ui/widgets/board/option_wheel.dart` (1101 lines)

## Purpose

Radial context menu displayed on long-press of a board artefact. Provides actions: play audio, change sound, toggle name visibility, rename, and resize. Animated arc layout with staggered button reveal.

## Class: `OptionWheel` extends `StatefulWidget`

### Props
- `artefact` — the artefact being acted on
- `showName` — current name visibility state
- `playSound` — callback to play artefact audio
- `onResize` — callback to enter resize mode
- `onToggleName` — callback with new visibility value
- `onPressed` — dismiss callback (called after action)
- `onSizeChange` — callback for size button
- `startDegrees` / `endDegrees` / `baseRadius` / `verticalNudge` — arc geometry

### Buttons (5)
1. **Audio** — plays artefact sound
2. **Skift lyd** (change sound) — opens sound option dialog (TTS / record / upload)
3. **Vis/Skjul Navn** — toggles artefact name visibility
4. **Skift navn** (change name) — text input dialog → `ArtefactController.updateArtefact`
5. **Størrelse** (size) — triggers resize mode

### Animation
- `AnimationController` (360ms) drives arc expansion from center
- Per-button staggered scale (0.6→1.0) and opacity (0→1) with `Interval` curves
- `_ArcBackgroundPainter` draws semi-transparent arc behind buttons via `CustomPaint`

### Sound Change Dialogs (`_showChangeSoundDialog`)
Three options via `_SoundOption` enum:
1. **Tekst til tale** — text input + voice selector (male/female) → POST to `Users/Artefacts/generate-speech-and-save` with artefactId → saves directly server-side
2. **Optag lyd** — microphone recording (AAC-LC) with timer display → uploads via `ArtefactController.updateArtefact`
3. **Upload lydfil** — `FilePicker` audio → uploads via `ArtefactController.updateArtefact`

### Helper Widgets
- `_OptionWheelButton` — individual button with icon + label in a rounded `ElevatedButton`
- `_ArcBackgroundPainter` — `CustomPainter` drawing the arc path

### Design Notes
- 1101 lines — second largest widget; contains significant TTS/recording logic duplicated from `AddItemPopup`
- TTS endpoint differs from AddItemPopup: uses `generate-speech-and-save` (saves server-side) vs `generate-speech-simple` (returns bytes)
- Dismiss on tap outside buttons via hit-testing button rects
- All strings in Danish
- `rootNavigator: true` used for loading dialogs to survive wheel closure
