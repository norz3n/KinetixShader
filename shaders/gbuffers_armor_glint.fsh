#version 330 compatibility

uniform sampler2D gtexture;

in vec2 vTexCoord;
in vec4 vColor;

/* RENDERTARGETS: 0,2 */
layout(location = 0) out vec4 outColor0;
layout(location = 1) out vec4 outColor2;

void main() {
    vec4 col = texture(gtexture, vTexCoord) * vColor;
    if (col.a < 0.02) {
        discard;
    }
    outColor0 = vec4(pow(col.rgb, vec3(2.2)) * 2.0, col.a);
    outColor2 = vec4(0.95, 1.0, 1.0, 1.0);
}
