# Pip — Living Reef guide art

`pearl-seahorse.webp` is the transparent painted cutout used by the three optional Pip guide encounters. The runtime retains the full 1024 × 1536 RGBA image and presents an `AtlasTexture` crop at `Rect2(180, 40, 740, 1450)`, drawn 91 world pixels tall. The crop and display scale do not resize or repaint the master file.

## Generation provenance

Created with the built-in `tools.image_gen__imagegen` tool, with `transparent_background: true` and the prompt below. No reference image was supplied. The tool did not expose a model identifier; none is inferred here.

Original tool output: `/workspace/scratch/091ee3a3346e/generated_images/exec-c1903864-1bcd-469a-b9e6-e817bd29f94e.png`.

Full prompt:

> Use case: stylized-concept. Asset type: transparent cutout sprite for a richly painted children's underwater adventure game. Create ONE adorable tiny baby seahorse, full body, facing right in a gentle three-quarter side view, with a beautifully curled tail, soft coral-pink and pearlescent peach body, small turquoise translucent dorsal fin, rounded little snout, large kind expressive dark eyes with jewel highlights, soft rounded dimensional shading and luminous painted texture. Elegant storybook game illustration, detailed and polished like a hand-painted 3D animated film character, warm friendly smile, graceful cute proportions. It should read beautifully at 90 pixels tall with a clear silhouette and restrained detail. Center the entire isolated character with comfortable transparent margins. Actual transparent background and clean alpha edges. No scenery, rocks, floor, shadows on a floor, decorative objects, floating bubbles, text, captions, logos or watermark. Only one seahorse, not a sprite sheet.

## Lossless runtime conversion

Pillow 12.3.0 opened the original as RGBA and saved it using `format='WEBP', lossless=True, exact=True`. No resizing, background removal, retouching or painting was performed. The WebP is the sole repository master; a redundant PNG copy is not required at runtime.

Equivalent conversion and verification:

```python
from PIL import Image, ImageChops

original = Image.open(source_png).convert('RGBA')
original.save(runtime_webp, format='WEBP', lossless=True, exact=True)
decoded = Image.open(runtime_webp).convert('RGBA')
assert original.size == decoded.size == (1024, 1536)
assert original.tobytes() == decoded.tobytes()
assert ImageChops.difference(original, decoded).getbbox(alpha_only=False) is None
```

The decoded RGBA bytes were verified equal, including transparent-pixel colour channels. Both images retain their original dimensions and alpha.

| File | Bytes | SHA-256 |
| --- | ---: | --- |
| Original generated PNG | 2,011,391 | `8a76e0d6147f3bfb2e8ad77e6a7b0c247addd76c19ed6789647451d2699e45a2` |
| Runtime `pearl-seahorse.webp` | 1,320,780 | `ee314a1a3b6dad8f580cdc92d62f46bc198736d39c7d93aef6807a539409ff1c` |

Godot imports the runtime WebP as a 2D texture. The guide’s gentle bob/facing and the surrounding flower/home flourishes are runtime presentation; the source image contains only one isolated seahorse.
