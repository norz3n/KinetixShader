#version 330 compatibility

#include "/lib/config.glsl"

uniform sampler2D gtexture;
uniform float frameTimeCounter;

in vec2 vTexCoord;
in vec2 vLmCoord;
in vec4 vColor;
in vec3 vWorldNormal;
in vec3 vWorldPos;
in float vBlockId;

/* RENDERTARGETS: 0,1,2 */
layout(location = 0) out vec4 outColor0;
layout(location = 1) out vec4 outColor1;
layout(location = 2) out vec4 outColor2;

#include "/lib/common.glsl"

vec3 computeWaterNormal(vec3 worldPos, vec3 baseNormal, float time) {
    float t = time * 1.75 * WIND_SPEED;
    vec2 p = worldPos.xz * 1.65;

    float dx = cos(p.x * 1.4 + p.y * 0.9 + t) * 1.4
             - sin(p.x * 0.8 - p.y * 1.7 - t * 1.3) * 0.8
             + cos(p.x * 3.1 + p.y * 2.4 + t * 2.1) * 0.45;
    float dz = cos(p.x * 1.4 + p.y * 0.9 + t) * 0.9
             + sin(p.x * 0.8 - p.y * 1.7 - t * 1.3) * 1.7
             + cos(p.x * 3.1 + p.y * 2.4 + t * 2.1) * 0.35;

    vec3 wavePerturb = vec3(-dx, 0.0, -dz) * (0.045 * WATER_WAVES);
    return normalize(baseNormal + wavePerturb);
}

void main() {
    vec4 texSample = texture(gtexture, vTexCoord) * vColor;
    if (texSample.a < 0.02) {
        discard;
    }

    int blockId = int(vBlockId + 0.5);
    bool isWater = (blockId == 10009);
    vec3 normal = normalize(vWorldNormal);
    vec2 lm = clamp(vLmCoord, 0.0, 1.0);

    if (isWater) {
        normal = computeWaterNormal(vWorldPos, normal, frameTimeCounter);
        vec3 biomeWater = pow(vColor.rgb, vec3(2.2));
        vec3 waterTint = mix(vec3(0.04, 0.28, 0.38), biomeWater * vec3(0.18, 0.55, 0.72), 0.50);
        outColor0 = vec4(waterTint, 0.22);
        outColor1 = vec4(encodeNormal(normal), lm.x, 1.0);
        outColor2 = vec4(0.75, lm.y, 0.0, 1.0);
    } else {
        vec3 linearCol = pow(texSample.rgb, vec3(2.2));
        outColor0 = vec4(linearCol, texSample.a);
        outColor1 = vec4(encodeNormal(normal), lm.x, 1.0);
        outColor2 = vec4(0.50, lm.y, 0.0, 1.0);
    }
}
