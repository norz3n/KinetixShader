// ====================================================================
// AstraCHS 1.21.1 - High-Performance Contact-Hardening Shadows (PCSS / CHS)
// MUST be included AFTER all in/out/uniform declarations!
// ====================================================================

#ifndef PCSS_GLSL
#define PCSS_GLSL

#include "/lib/common.glsl"
#include "/lib/distortion.glsl"

vec2 vogelDiskSample(int sampleIndex, int numSamples, float phi) {
    float r = sqrt((float(sampleIndex) + 0.5) / float(numSamples));
    float theta = float(sampleIndex) * GOLDEN_ANGLE + phi;
    return vec2(cos(theta), sin(theta)) * r;
}

vec3 computePCSSShadow(
    sampler2D shadowtex0,
    sampler2D shadowtex1,
    sampler2D shadowcolor0,
    vec3 worldPos,
    vec3 worldNormal,
    float NdotL,
    float skyLight,
    mat4 shadowModelView,
    mat4 shadowProjection,
    vec2 pixelCoord,
    int frame
) {
#if SHADOW_QUALITY == 0
    return vec3(1.0);
#else
    if (NdotL <= 0.001 || skyLight <= 0.015) {
        return vec3(0.0);
    }

    float distSq = dot(worldPos.xz, worldPos.xz) + worldPos.y * worldPos.y * 0.35;
    float maxDistSq = shadowDistance * shadowDistance;
    if (distSq >= maxDistSq) {
        return vec3(1.0);
    }
    float distanceFade = clamp((maxDistSq - distSq) / (maxDistSq * 0.18), 0.0, 1.0);

    float distFromCam = sqrt(distSq);
    float normalOffsetScale = (0.022 + 0.00045 * distFromCam) * (1024.0 / float(shadowMapResolution));
    float slopeFactor = clamp(1.0 - NdotL, 0.15, 0.85);
    vec3 biasedWorldPos = worldPos + worldNormal * (normalOffsetScale * (0.6 + slopeFactor));

    vec4 shadowViewPos = shadowModelView * vec4(biasedWorldPos, 1.0);
    vec4 shadowClipPos = shadowProjection * shadowViewPos;

    float distortFactor = getShadowDistortionFactor(shadowClipPos.xy);
    vec3 distortedClip = distortShadowClipPos(shadowClipPos.xyz);
    vec3 shadowCoord = distortedClip * 0.5 + 0.5;

    if (shadowCoord.x <= 0.002 || shadowCoord.x >= 0.998 ||
        shadowCoord.y <= 0.002 || shadowCoord.y >= 0.998 ||
        shadowCoord.z <= 0.0001 || shadowCoord.z >= 0.9999) {
        return vec3(1.0);
    }

    float depthBias = (0.00018 * distortFactor * distortFactor) / max(NdotL, 0.25);
    float receiverDepth = shadowCoord.z - depthBias;

    float noise = interleavedGradientNoise(pixelCoord, frame);
    float phi = noise * (2.0 * PI);

    float invRes = 1.0 / float(shadowMapResolution);
    float baseTexelRadius = invRes / max(distortFactor, 0.15);

#ifdef PCSS_ENABLED
    float searchRadius = baseTexelRadius * (2.6 * PCSS_SOFTNESS);
    float blockerDepthSum = 0.0;
    int blockerCount = 0;

    float centerDepth = texture(shadowtex1, shadowCoord.xy).r;
    if (centerDepth < receiverDepth) {
        blockerDepthSum += centerDepth;
        blockerCount += 1;
    }

    for (int i = 0; i < PCSS_BLOCKER_SAMPLES; ++i) {
        vec2 offset = vogelDiskSample(i, PCSS_BLOCKER_SAMPLES, phi) * searchRadius;
        float sampleDepth = texture(shadowtex1, shadowCoord.xy + offset).r;
        if (sampleDepth < receiverDepth) {
            blockerDepthSum += sampleDepth;
            blockerCount += 1;
        }
    }

    if (blockerCount == 0) {
    #ifdef COLORED_SHADOWS
        float transDepth = texture(shadowtex0, shadowCoord.xy).r;
        if (transDepth < receiverDepth) {
            vec4 sCol = texture(shadowcolor0, shadowCoord.xy);
            vec3 tinted = mix(vec3(1.0), sCol.rgb * (1.0 - sCol.a * 0.65), sCol.a);
            return mix(vec3(1.0), tinted, distanceFade);
        }
    #endif
        return vec3(1.0);
    }

    float avgBlockerDepth = blockerDepthSum / float(blockerCount);
    float blockerDist = max(receiverDepth - avgBlockerDepth, 0.0);

    float contactHardness = clamp((blockerDist * 95.0) / max(PCSS_CONTACT_SHARPNESS, 0.25), 0.0, 1.0);
    float penumbraScale = smoothstep(0.0, 1.0, contactHardness);

    float minPenumbra = baseTexelRadius * 0.45;
    float maxPenumbra = baseTexelRadius * (3.2 * PCSS_SOFTNESS);
    float filterRadius = mix(minPenumbra, maxPenumbra, penumbraScale);
#else
    float filterRadius = baseTexelRadius * 1.15;
#endif

    float opaqueShadow = 0.0;
    for (int i = 0; i < PCSS_PCF_SAMPLES; ++i) {
        vec2 offset = vogelDiskSample(i, PCSS_PCF_SAMPLES, phi + 1.047197) * filterRadius;
        float d = texture(shadowtex1, shadowCoord.xy + offset).r;
        opaqueShadow += (receiverDepth <= d) ? 1.0 : 0.0;
    }
    opaqueShadow /= float(PCSS_PCF_SAMPLES);

    vec3 finalShadow = vec3(opaqueShadow);

#ifdef COLORED_SHADOWS
    if (opaqueShadow > 0.02) {
        float transDepth = texture(shadowtex0, shadowCoord.xy).r;
        if (transDepth < receiverDepth) {
            vec4 sCol = texture(shadowcolor0, shadowCoord.xy);
            vec3 glassTint = mix(vec3(1.0), sCol.rgb * 1.15, clamp(sCol.a * 1.25, 0.0, 0.92));
            finalShadow *= glassTint * (1.0 - sCol.a * 0.35);
        }
    }
#endif

    return mix(vec3(1.0), finalShadow, distanceFade);
#endif
}

#endif
