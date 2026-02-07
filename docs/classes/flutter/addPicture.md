# AIPage / AddPicturePage

**File:** `Frontend/vta_app/lib/src/ui/widgets/categories/addPicture.dart` (451 lines)

## Purpose

AI image generation dialog using OpenAI DALL-E 3. Also contains a legacy `AddPicturePage` scaffold (largely superseded by `AddItemPopup`).

## Class: `AIPage` extends `StatefulWidget`

### Props
- `onImageProcessed(String imageBytes)` — callback with base64-encoded image data

### Flow
1. User selects image style: Piktogram / Realistisk / Tegning
2. Enters text prompt describing desired image
3. Generates image via OpenAI DALL-E 3 API
4. Displays preview → "Gem billede" saves via callback

### Image Styles (Danish prompts)
| Style | Prompt Template |
|-------|----------------|
| Piktogram | White background, single icon, child-friendly, continuous line art, no text |
| Realistisk | Realistic style, minimal background detail, child-friendly, high-quality |
| Tegning | White background, sketch style, black and white, child-friendly |

### API Call (`generateImage`)
- POST to `https://api.openai.com/v1/images/generations`
- Model: `dall-e-3`, size: `1024x1024`, format: `b64_json`
- API key loaded from `GlobalConfiguration().appConfig['OpenAi']['ApiKey']`

### Design Notes
- Returns base64 string (not bytes) — caller must decode
- API key stored in app config (not environment variable)
- All UI text in Danish

## Class: `AddPicturePage` extends `StatelessWidget`

Legacy full-screen scaffold with three FABs (upload, camera, AI). Camera and AI buttons both open `AIPage`. The upload button picks a file but doesn't do anything with it (dead code). Largely superseded by `AddItemPopup`'s inline image source buttons.
