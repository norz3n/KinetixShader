#version 330 compatibility

#include "/lib/config.glsl"

uniform sampler2D gtexture;
uniform float alphaTestRef;

in vec2 vTexCoord;
in vec2 vLmCoord;
in vec4 vColor;
in vec3 vWorldNormal;
in float vBlockId;

/* RENDERTARGETS: 0,1,2 */
layout(location = 0) out vec4 outColor0;
layout(location = 1) out vec4 outColor1;
layout(location = 2) out vec4 outColor2;

#include "/lib/common.glsl"

void main() {
    vec4 texSample = texture(gtexture, vTexCoord);
    vec4 albedo = vec4(texSample.rgb * vColor.rgb, texSample.a);
    if (albedo.a < max(alphaTestRef, 0.05)) {
        discard;
    }

    int blockId = int(vBlockId + 0.5);
    float ao = clamp(vColor.a, 0.25, 1.0);
    vec3 linearAlbedo = pow(albedo.rgb, vec3(2.2)) * mix(1.0, ao, 0.85);

    bool isFoliage = (blockId >= 10001 && blockId <= 10007);
    bool isEmissive = (blockId == 10010 || blockId == 10011 || blockId == 10008);

    float matFlag = isFoliage ? 0.25 : 0.10;
    float emissive = isEmissive ? 1.0 : 0.0;
    vec2 lm = clamp(vLmCoord, 0.0, 1.0);

    outColor0 = vec4(linearAlbedo, 1.0);
    outColor1 = vec4(encodeNormal(normalize(vWorldNormal)), lm.x, 1.0);
    outColor2 = vec4(matFlag, lm.y, emissive, 1.0);
}
