#version 330 compatibility

#include "/lib/config.glsl"

uniform sampler2D gtexture;

in vec2 vTexCoord;
in vec2 vLmCoord;
in vec4 vColor;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 outColor0;

void main() {
    vec4 albedo = texture(gtexture, vTexCoord) * vColor;
    if (albedo.a < 0.05) {
        discard;
    }
    vec3 linearCol = pow(albedo.rgb, vec3(2.2)) * 0.75;
    outColor0 = vec4(linearCol, albedo.a * 0.55);
}
