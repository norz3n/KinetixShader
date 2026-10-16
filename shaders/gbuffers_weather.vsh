#version 330 compatibility

#include "/lib/config.glsl"

uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform vec3 cameraPosition;
uniform float frameTimeCounter;

out vec2 vTexCoord;
out vec2 vLmCoord;
out vec4 vColor;

void main() {
    vTexCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    vLmCoord  = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
    vColor    = gl_Color;

    vec4 viewPos = gl_ModelViewMatrix * gl_Vertex;
    vec3 worldRelCam = (gbufferModelViewInverse * viewPos).xyz;

#ifdef WAVING_WEATHER
    float t = frameTimeCounter * WIND_SPEED;
    vec2 windTilt = vec2(sin(t * 0.8) * 0.35 + 0.45, cos(t * 0.6) * 0.25) * WIND_STRENGTH;
    worldRelCam.xz += windTilt * clamp(worldRelCam.y * 0.18, -1.5, 1.5);
#endif

    gl_Position = gl_ProjectionMatrix * (gbufferModelView * vec4(worldRelCam, 1.0));
}
