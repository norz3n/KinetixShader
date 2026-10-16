// ====================================================================
// AstraCHS 1.21.1 - Hyperbolic Shadow Map Distortion
// MUST be included AFTER all in/out/uniform declarations!
// ====================================================================

#ifndef DISTORTION_GLSL
#define DISTORTION_GLSL

float getShadowDistortionFactor(vec2 shadowClipXY) {
    vec2 p2 = shadowClipXY * shadowClipXY;
    float dist = sqrt(sqrt(p2.x * p2.x + p2.y * p2.y) + 1e-6);
    return mix(1.0, dist, SHADOW_DISTORT_FACTOR);
}

vec3 distortShadowClipPos(vec3 shadowClipPos) {
    float distortFactor = getShadowDistortionFactor(shadowClipPos.xy);
    shadowClipPos.xy /= distortFactor;
    shadowClipPos.z *= 0.2;
    return shadowClipPos;
}

#endif
