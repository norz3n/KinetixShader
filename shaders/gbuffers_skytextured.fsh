#version 330 compatibility

#include "/lib/config.glsl"

uniform sampler2D gtexture;

in vec2 vTexCoord;
in vec4 vColor;

/* RENDERTARGETS: 0,2 */
layout(location = 0) out vec4 outColor0;
layout(location = 1) out vec4 outColor2;

void main() {
    vec4 texCol = texture(gtexture, vTexCoord) * vColor;
    if (texCol.a < 0.05) {
        discard;
    }
    vec3 hdrCelestial = pow(texCol.rgb, vec3(2.2)) * 3.2;
    outColor0 = vec4(hdrCelestial, texCol.a);
    outColor2 = vec4(0.95, 1.0, 1.0, 1.0);
}
