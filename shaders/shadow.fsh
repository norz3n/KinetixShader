#version 330 compatibility

#include "/lib/config.glsl"

uniform sampler2D tex;

in vec2 vTexCoord;
in vec4 vColor;
in float vBlockId;

layout(location = 0) out vec4 shadowColor0;

void main() {
    vec4 albedo = texture(tex, vTexCoord) * vColor;
    if (albedo.a < 0.1) {
        discard;
    }

    int blockId = int(vBlockId + 0.5);
    if (blockId == 10009) {
        shadowColor0 = vec4(0.18, 0.58, 0.72, 0.35);
    } else {
        shadowColor0 = albedo;
    }
}
