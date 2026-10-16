// ====================================================================
// AstraCHS 1.21.1 - Pure Macro Configuration (Safe before declarations)
// ====================================================================

#ifndef CONFIG_GLSL
#define CONFIG_GLSL

// --- Shadow & PCSS / CHS Settings ---
#define SHADOW_QUALITY 2            // [0 1 2 3]
#define shadowMapResolution 1024    // [512 768 1024 1536 2048 3072 4096]
#define shadowDistance 64.0         // [32.0 48.0 64.0 80.0 96.0 128.0 160.0]

#define PCSS_ENABLED                // Enables Nvidia PCSS / AMD CHS Contact Hardening
#define PCSS_SOFTNESS 1.0           // [0.4 0.6 0.8 1.0 1.25 1.5 2.0]
#define PCSS_CONTACT_SHARPNESS 1.0  // [0.5 0.75 1.0 1.25 1.5 2.0]
#define PCSS_BLOCKER_SAMPLES 4      // [2 4 6 8]
#define PCSS_PCF_SAMPLES 8          // [4 6 8 12 16]
#define COLORED_SHADOWS             // Colored stained-glass & water shadows

// --- World Animation ("Всё, что движется") ---
#define WAVING_ALL                  // Master toggle for all moving geometry
#define WAVING_TERRAIN              // Short grass, tall grass, ferns, flowers, leaves
#define WAVING_CROPS                // Wheat, carrots, potatoes, beetroots, stems
#define WAVING_VINES                // Vines, cave vines, weeping/twisting vines, sugar cane, fire
#define WAVING_UNDERWATER           // Kelp, seagrass, coral fans
#define WAVING_LANTERNS             // Hanging lanterns, soul lanterns, chains, bells, lily pads
#define WAVING_WATER                // Geometric water & lava surface waves
#define WAVING_WEATHER              // Wind-angled rain and snow

#define WIND_SPEED 1.0              // [0.5 0.75 1.0 1.25 1.5 2.0]
#define WIND_STRENGTH 1.0           // [0.5 0.75 1.0 1.25 1.5 2.0]

// --- Water, Atmosphere & Lighting ---
#define WATER_SSR                   // Lightweight 6-step screen-space reflections on water
#define WATER_CAUSTICS              // Procedural underwater light caustics & shoreline foam
#define WATER_WAVES 1.0             // [0.5 0.75 1.0 1.25 1.5]
#define WATER_FOAM_OPACITY 0.72     // [0.35 0.50 0.72 0.85 1.0]
#define GODRAYS                     // Fast interleaved screen-space sun shafts
#define FOG_DENSITY 1.0             // [0.25 0.5 0.75 1.0 1.25 1.5 2.0]
#define DYNAMIC_HANDLIGHT           // Warm dynamic lighting when holding torches/lanterns
#define FLICKER_TORCH               // Organic subtle flickering on blocklight
#define FOLIAGE_SSS                 // Subsurface scattering on leaves & grass

// --- Post-Processing ---
#define TONEMAP_OPERATOR 0          // [0 1] 0 = ACES Filmic, 1 = Lottes Neutral
#define BLOOM_ENABLED               // Fast 5-tap HDR glow
#define BLOOM_STRENGTH 0.16         // [0.05 0.10 0.16 0.25 0.35]
#define CAS_SHARPEN                 // AMD FidelityFX Contrast-Adaptive Sharpening
#define CAS_STRENGTH 0.45           // [0.15 0.30 0.45 0.65 0.85]
#define VIBRANCE 1.12               // [0.90 1.00 1.08 1.12 1.20 1.30]

// --- Mathematical Constants ---
#define PI 3.14159265359
#define GOLDEN_ANGLE 2.399963229728653
#define SHADOW_DISTORT_FACTOR 0.86

#endif
