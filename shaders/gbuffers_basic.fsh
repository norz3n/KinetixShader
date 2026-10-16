#version 330 compatibility

in vec4 vColor;

/* RENDERTARGETS: 0,2 */
layout(location = 0) out vec4 outColor0;
layout(location = 1) out vec4 outColor2;

void main() {
    if (vColor.a < 0.05) {
        discard;
    }
    outColor0 = vec4(pow(vColor.rgb, vec3(2.2)), vColor.a);
    outColor2 = vec4(0.95, 1.0, 0.0, 1.0);
}
