#version 330 compatibility

uniform sampler2D gtexture;

in vec2 vTexCoord;
in vec2 vLmCoord;
in vec4 vColor;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 outColor0;

void main() {
    vec4 col = texture(gtexture, vTexCoord) * vColor;
    if (col.a < 0.05) {
        discard;
    }
    outColor0 = vec4(pow(col.rgb, vec3(2.2)), col.a);
}
