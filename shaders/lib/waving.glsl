// ====================================================================
// AstraCHS 1.21.1 - Complete World Animation Library ("Всё, что движется")
// MUST be included AFTER all in/out/uniform declarations!
// ====================================================================

#ifndef WAVING_GLSL
#define WAVING_GLSL

vec3 windTurbulence(vec3 worldPos, float time, float gustStrength) {
    float t = time * WIND_SPEED;
    float mainPhase = dot(worldPos.xz, vec2(0.42, 0.27)) - t * 2.1;
    float gust = 0.65 + 0.35 * sin(dot(worldPos.xz, vec2(0.09, 0.06)) - t * 0.75);
    float waveX = sin(mainPhase) + 0.45 * cos(mainPhase * 1.9 + worldPos.y * 0.8);
    float waveZ = cos(mainPhase * 0.85 + 1.1) + 0.35 * sin(mainPhase * 2.1 - worldPos.x * 0.6);
    float waveY = 0.25 * sin(mainPhase * 1.6 + worldPos.z);
    return vec3(waveX, waveY, waveZ) * (gust * gustStrength * WIND_STRENGTH);
}

vec3 applyWorldWaving(
    vec3 viewFromCameraPos,
    vec3 cameraPos,
    vec2 texCoord,
    vec2 midTexCoord,
    int blockId,
    float skyLight,
    float rainStrengthVal,
    float time
) {
#ifndef WAVING_ALL
    return viewFromCameraPos;
#else
    if (blockId < 10001 || blockId > 10010) {
        return viewFromCameraPos;
    }

    vec3 worldPos = viewFromCameraPos + cameraPos;
    float weatherBoost = 1.0 + rainStrengthVal * 0.45;
    float outdoorFactor = mix(0.25, 1.0, smoothstep(0.05, 0.65, skyLight)) * weatherBoost;

    bool isTopVertex = (texCoord.y < midTexCoord.y);
    float topMask = isTopVertex ? 1.0 : 0.0;

#ifdef WAVING_TERRAIN
    if (blockId == 10001) {
        vec3 wind = windTurbulence(worldPos, time, 0.065 * outdoorFactor);
        viewFromCameraPos.xz += wind.xz * topMask;
        viewFromCameraPos.y  -= length(wind.xz) * 0.15 * topMask;
        return viewFromCameraPos;
    }

    if (blockId == 10002) {
        vec3 wind = windTurbulence(worldPos, time, 0.045 * outdoorFactor);
        float flutter = sin(time * 5.2 * WIND_SPEED + dot(worldPos, vec3(2.7, 3.1, 2.3))) * 0.012 * WIND_STRENGTH * outdoorFactor;
        viewFromCameraPos.xyz += wind + vec3(flutter, flutter * 0.6, -flutter);
        return viewFromCameraPos;
    }

    if (blockId == 10004) {
        vec3 wind = windTurbulence(worldPos, time, 0.055 * outdoorFactor);
        viewFromCameraPos.xz += wind.xz * (0.5 * topMask);
        return viewFromCameraPos;
    }

    if (blockId == 10005) {
        vec3 baseWorldPos = vec3(worldPos.x, floor(worldPos.y), worldPos.z);
        vec3 wind = windTurbulence(baseWorldPos, time, 0.055 * outdoorFactor);
        float heightWeight = isTopVertex ? 1.15 : 0.50;
        viewFromCameraPos.xz += wind.xz * heightWeight;
        viewFromCameraPos.y  -= length(wind.xz) * 0.12 * topMask;
        return viewFromCameraPos;
    }
#endif

#ifdef WAVING_CROPS
    if (blockId == 10003) {
        float t = time * WIND_SPEED;
        float ripple = sin(dot(worldPos.xz, vec2(0.65, 0.45)) - t * 2.8) * 0.048 * WIND_STRENGTH * outdoorFactor;
        float crossRipple = cos(dot(worldPos.xz, vec2(-0.35, 0.70)) - t * 2.1) * 0.025 * WIND_STRENGTH * outdoorFactor;
        viewFromCameraPos.xz += vec2(ripple, crossRipple) * topMask;
        return viewFromCameraPos;
    }
#endif

#ifdef WAVING_VINES
    if (blockId == 10006) {
        vec3 wind = windTurbulence(worldPos, time * 1.15, 0.042 * outdoorFactor);
        viewFromCameraPos.xz += wind.xz * (0.35 + 0.65 * topMask);
        return viewFromCameraPos;
    }
#endif

#ifdef WAVING_UNDERWATER
    if (blockId == 10007) {
        float t = time * 1.4 * WIND_SPEED;
        float currentX = sin(worldPos.y * 1.4 + worldPos.x * 0.7 - t) * 0.055 * WIND_STRENGTH;
        float currentZ = cos(worldPos.y * 1.2 + worldPos.z * 0.8 - t * 0.9) * 0.045 * WIND_STRENGTH;
        float mask = (topMask * 0.7 + 0.3);
        viewFromCameraPos.xz += vec2(currentX, currentZ) * mask;
        return viewFromCameraPos;
    }
#endif

#ifdef WAVING_LANTERNS
    if (blockId == 10008) {
        float t = time * WIND_SPEED;
        float bottomMask = isTopVertex ? 0.25 : 1.0;
        float swingPhase = t * 2.4 + floor(worldPos.x) * 1.7 + floor(worldPos.z) * 2.3;
        vec2 swing = vec2(sin(swingPhase), cos(swingPhase * 0.85)) * (0.028 * WIND_STRENGTH * outdoorFactor * bottomMask);
        viewFromCameraPos.xz += swing;
        return viewFromCameraPos;
    }
#endif

#ifdef WAVING_WATER
    if (blockId == 10009) {
        float fractY = fract(worldPos.y + 0.005);
        if (fractY > 0.05) {
            float t = time * 1.8 * WIND_SPEED;
            float w1 = sin(worldPos.x * 1.35 + worldPos.z * 0.85 + t) * 0.038;
            float w2 = cos(worldPos.x * 0.75 - worldPos.z * 1.55 - t * 1.25) * 0.024;
            viewFromCameraPos.y += (w1 + w2) * WATER_WAVES;
        }
        return viewFromCameraPos;
    }

    if (blockId == 10010) {
        float fractY = fract(worldPos.y + 0.005);
        if (fractY > 0.05) {
            float t = time * 0.85;
            float lavaWave = sin(worldPos.x * 0.9 + t) * cos(worldPos.z * 0.9 - t * 0.7) * 0.032;
            viewFromCameraPos.y += lavaWave;
        }
        return viewFromCameraPos;
    }
#endif

    return viewFromCameraPos;
#endif
}

#endif
