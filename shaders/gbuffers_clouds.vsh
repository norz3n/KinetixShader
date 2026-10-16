#version 330 compatibility

#include "/lib/config.glsl"

uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform float frameTimeCounter;

out vec2 vTexCoord;
out vec4 vColor;
out vec3 vWorldNormal;

void main() {
    vTexCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    vColor = gl_Color;

    vec3 viewNormal = normalize(gl_NormalMatrix * gl_Normal);
    vWorldNormal = normalize((gbufferModelViewInverse * vec4(viewNormal, 0.0)).xyz);

    vec4 viewPos = gl_ModelViewMatrix * gl_Vertex;
    vec3 worldRelCam = (gbufferModelViewInverse * viewPos).xyz;
#ifdef WAVING_ALL
    worldRelCam.y += sin(worldRelCam.x * 0.04 + frameTimeCounter * 0.6) * 0.35;
#endif
    gl_Position = gl_ProjectionMatrix * (gbufferModelView * vec4(worldRelCam, 1.0));
}
