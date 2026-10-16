#version 330 compatibility

#include "/lib/config.glsl"

uniform sampler2D gtexture;

in vec2 vTexCoord;
in vec4 vColor;
in vec3 vWorldNormal;

/* RENDERTARGETS: 0,1,2 */
layout(location = 0) out vec4 outColor0;
layout(location = 1) out vec4 outColor1;
layout(location = 2) out vec4 outColor2;

#include "/lib/common.glsl"

void main() {
    vec4 albedo = texture(gtexture, vTexCoord) * vColor;
    if (albedo.a < 0.05) {
        discard;
    }
    vec3 linearCol = pow(albedo.rgb, vec3(2.2));
    outColor0 = vec4(linearCol, albedo.a * 0.85);
    outColor1 = vec4(encodeNormal(normalize(vWorldNormal)), 0.0, 1.0);
    outColor2 = vec4(0.95, 1.0, 0.0, 1.0);
}
