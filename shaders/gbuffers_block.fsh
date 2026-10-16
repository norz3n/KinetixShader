#version 330 compatibility

#include "/lib/config.glsl"

uniform sampler2D gtexture;
uniform float alphaTestRef;

in vec2 vTexCoord;
in vec2 vLmCoord;
in vec4 vColor;
in vec3 vWorldNormal;

/* RENDERTARGETS: 0,1,2 */
layout(location = 0) out vec4 outColor0;
layout(location = 1) out vec4 outColor1;
layout(location = 2) out vec4 outColor2;

#include "/lib/common.glsl"

void main() {
    vec4 albedo = texture(gtexture, vTexCoord) * vColor;
    if (albedo.a < max(alphaTestRef, 0.05)) {
        discard;
    }

    vec3 linearAlbedo = pow(albedo.rgb, vec3(2.2));
    vec2 lm = clamp(vLmCoord, 0.0, 1.0);

    outColor0 = vec4(linearAlbedo, albedo.a);
    outColor1 = vec4(encodeNormal(normalize(vWorldNormal)), lm.x, 1.0);
    outColor2 = vec4(0.10, lm.y, 0.0, 1.0);
}
