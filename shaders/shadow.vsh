#version 330 compatibility

#include "/lib/config.glsl"

in vec4 mc_Entity;
in vec4 mc_midTexCoord;
in vec4 at_tangent;

uniform mat4 shadowModelView;
uniform mat4 shadowModelViewInverse;
uniform mat4 shadowProjection;
uniform vec3 cameraPosition;
uniform float frameTimeCounter;
uniform float rainStrength;

out vec2 vTexCoord;
out vec4 vColor;
out float vBlockId;

#include "/lib/distortion.glsl"
#include "/lib/waving.glsl"

void main() {
    vTexCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    vColor = gl_Color;
    vBlockId = floor(mc_Entity.x + 0.5);

    vec2 lm = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
    float skyLight = clamp(lm.y, 0.0, 1.0);

    vec4 shadowViewPos = gl_ModelViewMatrix * gl_Vertex;
    vec3 worldRelCam = (shadowModelViewInverse * shadowViewPos).xyz;

    worldRelCam = applyWorldWaving(
        worldRelCam,
        cameraPosition,
        vTexCoord,
        mc_midTexCoord.xy,
        int(vBlockId),
        skyLight,
        rainStrength,
        frameTimeCounter
    );

    vec4 displacedShadowView = shadowModelView * vec4(worldRelCam, 1.0);
    vec4 clipPos = shadowProjection * displacedShadowView;
    clipPos.xyz = distortShadowClipPos(clipPos.xyz);

    gl_Position = clipPos;
}
