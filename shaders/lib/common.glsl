// ====================================================================
// AstraCHS 1.21.1 - Common Encoding, Noise & Caustics Functions
// MUST be included AFTER all in/out/uniform declarations!
// ====================================================================

#ifndef COMMON_GLSL
#define COMMON_GLSL

vec2 encodeNormal(vec3 n) {
    n /= (abs(n.x) + abs(n.y) + abs(n.z) + 1e-6);
    vec2 enc = (n.z >= 0.0) ? n.xy : ((1.0 - abs(n.yx)) * vec2(n.x >= 0.0 ? 1.0 : -1.0, n.y >= 0.0 ? 1.0 : -1.0));
    return enc * 0.5 + 0.5;
}

vec3 decodeNormal(vec2 enc) {
    enc = enc * 2.0 - 1.0;
    vec3 n = vec3(enc.xy, 1.0 - abs(enc.x) - abs(enc.y));
    float t = clamp(-n.z, 0.0, 1.0);
    n.x += (n.x >= 0.0) ? -t : t;
    n.y += (n.y >= 0.0) ? -t : t;
    return normalize(n);
}

float interleavedGradientNoise(vec2 pixelCoord, int frame) {
    vec2 p = pixelCoord + float(frame & 63) * vec2(5.588238, 3.141592);
    return fract(52.9829189 * fract(dot(p, vec2(0.06711056, 0.00583715))));
}

float computeCaustics(vec3 worldPos, float time) {
    vec2 p = worldPos.xz * 1.45 + vec2(worldPos.y * 0.35);
    float t = time * 1.6;
    float c1 = sin(p.x * 2.1 + t) * cos(p.y * 2.3 - t * 0.8);
    float c2 = sin((p.x - p.y) * 1.9 - t * 1.2) * cos((p.x + p.y) * 1.7 + t * 0.9);
    return pow(clamp(1.0 - abs(c1 + c2) * 0.65, 0.0, 1.0), 3.0);
}

#endif
