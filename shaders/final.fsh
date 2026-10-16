#version 330 compatibility

#include "/lib/config.glsl"

uniform sampler2D colortex0;
uniform float viewWidth;
uniform float viewHeight;
uniform int frameCounter;

in vec2 vTexCoord;

layout(location = 0) out vec4 finalColor;

#include "/lib/common.glsl"

vec3 tonemapACES(vec3 x) {
    x *= 0.88;
    const float a = 2.51;
    const float b = 0.03;
    const float c = 2.43;
    const float d = 0.59;
    const float e = 0.14;
    return clamp((x * (a * x + b)) / (x * (c * x + d) + e), 0.0, 1.0);
}

vec3 tonemapLottes(vec3 x) {
    vec3 a = vec3(1.35);
    vec3 d = vec3(0.92);
    vec3 hdrMax = vec3(8.0);
    vec3 midIn = vec3(0.18);
    vec3 midOut = vec3(0.22);

    vec3 b = (-pow(midIn, a) + pow(hdrMax, a) * midOut) /
             ((pow(hdrMax, a * d) - pow(midIn, a * d)) * midOut);
    vec3 c = (pow(hdrMax, a * d) * pow(midIn, a) - pow(hdrMax, a) * pow(midIn, a * d) * midOut) /
             ((pow(hdrMax, a * d) - pow(midIn, a * d)) * midOut);

    return clamp(pow(x, a) / (pow(x, a * d) * b + c), 0.0, 1.0);
}

vec3 sampleFastBloom(vec2 uv, vec2 texelSize) {
    vec3 b0 = max(texture(colortex0, uv + vec2(-2.5, -1.5) * texelSize).rgb - vec3(0.85), vec3(0.0));
    vec3 b1 = max(texture(colortex0, uv + vec2( 1.5, -2.5) * texelSize).rgb - vec3(0.85), vec3(0.0));
    vec3 b2 = max(texture(colortex0, uv + vec2( 2.5,  1.5) * texelSize).rgb - vec3(0.85), vec3(0.0));
    vec3 b3 = max(texture(colortex0, uv + vec2(-1.5,  2.5) * texelSize).rgb - vec3(0.85), vec3(0.0));
    vec3 b4 = max(texture(colortex0, uv + vec2( 4.5, -4.5) * texelSize).rgb - vec3(0.85), vec3(0.0));
    return (b0 + b1 + b2 + b3 + b4) * 0.2;
}

void main() {
    vec2 texel = 1.0 / vec2(max(viewWidth, 1.0), max(viewHeight, 1.0));
    vec3 center = texture(colortex0, vTexCoord).rgb;

#ifdef CAS_SHARPEN
    vec3 north = texture(colortex0, vTexCoord + vec2(0.0, -texel.y)).rgb;
    vec3 south = texture(colortex0, vTexCoord + vec2(0.0,  texel.y)).rgb;
    vec3 west  = texture(colortex0, vTexCoord + vec2(-texel.x, 0.0)).rgb;
    vec3 east  = texture(colortex0, vTexCoord + vec2( texel.x, 0.0)).rgb;

    vec3 minRGB = min(center, min(min(north, south), min(west, east)));
    vec3 maxRGB = max(center, max(max(north, south), max(west, east)));
    vec3 contrast = clamp(min(minRGB, 2.0 - maxRGB) / max(maxRGB, vec3(1e-4)), 0.0, 1.0);
    vec3 weight = -sqrt(contrast) * (0.125 * CAS_STRENGTH);

    center = max((center + (north + south + west + east) * weight) / (1.0 + 4.0 * weight), vec3(0.0));
#endif

#ifdef BLOOM_ENABLED
    vec3 bloom = sampleFastBloom(vTexCoord, texel * 2.0);
    center += bloom * BLOOM_STRENGTH;
#endif

#if TONEMAP_OPERATOR == 0
    vec3 mapped = tonemapACES(center);
#else
    vec3 mapped = tonemapLottes(center);
#endif

    vec3 srgb = pow(max(mapped, vec3(0.0)), vec3(1.0 / 2.2));

    float luma = dot(srgb, vec3(0.2126, 0.7152, 0.0722));
    float maxChan = max(srgb.r, max(srgb.g, srgb.b));
    float minChan = min(srgb.r, min(srgb.g, srgb.b));
    float sat = maxChan - minChan;
    srgb = mix(vec3(luma), srgb, 1.0 + (VIBRANCE - 1.0) * (1.0 - sat));

    float dither = (interleavedGradientNoise(gl_FragCoord.xy, frameCounter) - 0.5) / 255.0;
    srgb = clamp(srgb + dither, 0.0, 1.0);

    finalColor = vec4(srgb, 1.0);
}
