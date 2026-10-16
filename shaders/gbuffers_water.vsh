#version 330 compatibility

#include "/lib/config.glsl"

in vec4 mc_Entity;
in vec4 mc_midTexCoord;
in vec4 at_tangent;

uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform vec3 cameraPosition;
uniform float frameTimeCounter;
uniform float rainStrength;

out vec2 vTexCoord;
out vec2 vLmCoord;
out vec4 vColor;
out vec3 vWorldNormal;
out vec3 vWorldPos;
out float vBlockId;

#include "/lib/waving.glsl"

void main() {
    vTexCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    vLmCoord  = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
    vColor    = gl_Color;
    vBlockId  = floor(mc_Entity.x + 0.5);

    vec3 viewNormal = normalize(gl_NormalMatrix * gl_Normal);
    vWorldNormal = normalize((gbufferModelViewInverse * vec4(viewNormal, 0.0)).xyz);

    vec4 viewPos = gl_ModelViewMatrix * gl_Vertex;
    vec3 worldRelCam = (gbufferModelViewInverse * viewPos).xyz;

    worldRelCam = applyWorldWaving(
        worldRelCam,
        cameraPosition,
        vTexCoord,
        mc_midTexCoord.xy,
        int(vBlockId),
        clamp(vLmCoord.y, 0.0, 1.0),
        rainStrength,
        frameTimeCounter
    );

    vWorldPos = worldRelCam + cameraPosition;
    vec4 displacedViewPos = gbufferModelView * vec4(worldRelCam, 1.0);
    gl_Position = gl_ProjectionMatrix * displacedViewPos;
}
