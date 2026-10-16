#version 330 compatibility

#include "/lib/config.glsl"

uniform vec3 skyColor;
uniform vec3 fogColor;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;
uniform float viewWidth;
uniform float viewHeight;

in vec4 vColor;
in float vIsStar;

/* RENDERTARGETS: 0,2 */
layout(location = 0) out vec4 outColor0;
layout(location = 1) out vec4 outColor2;

void main() {
    vec3 finalSky;
    if (vIsStar > 0.5) {
        finalSky = pow(vColor.rgb, vec3(2.2)) * 2.2;
    } else {
        vec2 screenUV = gl_FragCoord.xy / vec2(max(viewWidth, 1.0), max(viewHeight, 1.0));
        vec4 clipPos = vec4(screenUV * 2.0 - 1.0, 1.0, 1.0);
        vec4 viewPos = gbufferProjectionInverse * clipPos;
        vec3 viewDir = normalize(viewPos.xyz / viewPos.w);
        vec3 worldDir = normalize((gbufferModelViewInverse * vec4(viewDir, 0.0)).xyz);

        float zenith = clamp(worldDir.y, 0.0, 1.0);
        vec3 zenCol = pow(skyColor, vec3(2.2));
        vec3 horCol = pow(fogColor, vec3(2.2));
        finalSky = mix(horCol, zenCol, pow(zenith, 0.58));
    }

    outColor0 = vec4(finalSky, 1.0);
    outColor2 = vec4(0.95, 1.0, 0.0, 1.0);
}
