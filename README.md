# KinetixShader

High-Performance Contact-Hardening Shader for Minecraft, built for smooth gameplay on integrated GPUs (Intel UHD 620/630, Iris Xe, AMD Vega) and scalable up to dedicated graphics cards.

Compatible with **Iris**, **Oculus**, **NeOculus**, and **Embeddium** (Minecraft 1.21.1+).

---

## Key Features

- **PCSS / Contact-Hardening Shadows**: Physically realistic shadows that soften naturally as distance from the occluder increases, with crisp contact points.
- **Ultra-Narrow G-Buffer Optimization**: Designed specifically for low memory bandwidth on integrated GPUs (`R11F_G11F_B10F` color buffers and selective translucent blending).
- **Colored Shadows**: Dynamic translucent shadow tinting through stained glass and water surfaces.
- **Full World Animation**:
  - Grass, ferns, flowers, and leaves.
  - Crops (wheat, carrots, potatoes, beetroots).
  - Vines, weeping/twisting vines, sugar cane, and fire.
  - Underwater kelp, seagrass, and corals.
  - Swinging lanterns, chains, and bells.
  - Geometric water waves and wind-angled precipitation.
- **Water & Atmosphere**:
  - Screen-Space Reflections (SSR) with low overhead.
  - Underwater caustics and shoreline foam.
  - Interleaved screen-space volumetric sun shafts (Godrays).
  - Atmospheric fog and organic torchlight flickering.
  - Subsurface scattering (SSS) on foliage.
- **Post-Processing**:
  - AMD FidelityFX Contrast-Adaptive Sharpening (CAS).
  - ACES Filmic and Neutral Lottes Tonemapping operators.
  - Fast 5-tap HDR bloom.

---

## Profiles

| Profile | Target Hardware | Shadow Map | Features |
| :--- | :--- | :--- | :--- |
| **Intel UHD 620/630** | Intel UHD Graphics, entry iGPUs | 768 | Fast PCSS, World Animation, Caustics, Bloom, CAS |
| **Balanced** | UHD 630, AMD Vega, Iris Xe | 1024 | PCSS, Colored Shadows, SSR, Godrays, Bloom, CAS |
| **Ultra PCSS** | Dedicated GPUs (GTX / RTX / Radeon) | 2048 | Ultra PCSS (6 blocker / 12 PCF samples), All effects enabled |
| **Shadowless Turbo** | Ultra-low-end / Battery saving | 512 | No shadow mapping, maximum framerate boost |

---

## Repository Structure

```text
KinetixShader/
├── shaders/
│   ├── lang/                  # Localization (en_US, ru_RU)
│   ├── lib/                   # GLSL libraries, PCSS, waving, config
│   ├── block.properties       # Block ID mappings
│   ├── shaders.properties     # Shader GUI layout, profiles & framebuffers
│   └── *.fsh, *.vsh           # Vertex and fragment shader stages
├── .gitignore
├── LICENSE
└── README.md
```

---

## Installation

### Option 1: Direct Folder (Recommended for development)
1. Clone or copy this repository folder into your `.minecraft/shaderpacks/` directory:
   ```bash
   git clone https://github.com/norz3n/KinetixShader.git ".minecraft/shaderpacks/KinetixShader"
   ```
2. Launch Minecraft with Iris or Oculus installed.
3. Select **KinetixShader** in **Video Settings > Shader Packs**.

### Option 2: Archive (.zip)
1. Compress the contents of this repository so that `shaders/` is at the root of the `.zip` archive.
2. Place the `.zip` file into `.minecraft/shaderpacks/`.

---

## License

This project is licensed under the MIT License - see the [LICENSE](file:///e:/Projects/Github/KinetixShader/LICENSE) file for details.
