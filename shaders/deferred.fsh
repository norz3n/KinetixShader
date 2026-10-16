#version 330 compatibility

#include "/lib/config.glsl"

uniform sampler2D colortex0;
uniform sampler2D colortex1;
uniform sampler2D colortex2;
uniform sampler2D depthtex0;
uniform sampler2D shadowtex0;
uniform sampler2D shadowtex1;
uniform sampler2D shadowcolor0;

uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;
uniform mat4 shadowModelView;
uniform mat4 shadowProjection;

uniform vec3 cameraPosition;
uniform vec3 shadowLightPosition;
uniform vec3 sunPosition;
uniform vec3 skyColor;
uniform vec3 fogColor;

uniform float rainStrength;
uniform float wetness;
uniform float frameTimeCounter;
uniform int frameCounter;
uniform int heldBlockLightValue;
uniform int heldBlockLightValue2;

in vec2 vTexCoord;

/* RENDERTARGETS: 0,2 */
layout(location = 0) out vec4 outColor0;
layout(location = 1) out vec4 outColor2;

#include "/lib/pcss.glsl"

vec3 reconstructViewPos(vec2 uv, float depth) {
    vec4 clipPos = vec4(uv * 2.0 - 1.0, depth * 2.0 - 1.0, 1.0);
    vec4 viewPos = gbufferProjectionInverse * clipPos;
    return viewPos.xyz / viewPos.w;
}

void main() {
    vec4 baseColor = texture(colortex0, vTexCoord);
    float depth = texture(depthtex0, vTexCoord).r;
    vec4 matInfo = texture(colortex2, vTexCoord);

    if (depth >= 0.999999 || matInfo.r >= 0.88) {
        outColor0 = baseColor;
        outColor2 = vec4(0.95, matInfo.g, matInfo.b, 1.0);
        return;
    }

    vec4 packedNormLm = texture(colortex1, vTexCoord);
    vec3 worldNormal  = decodeNormal(packedNormLm.xy);
    vec2 lightmap     = vec2(packedNormLm.z, matInfo.g);
    float matFlag     = matInfo.r;
    float emissive    = matInfo.b;

    vec3 viewPos  = reconstructViewPos(vTexCoord, depth);
    vec3 worldPos = (gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz;
    float viewDist = length(viewPos);

    vec3 lightViewDir  = normalize(shadowLightPosition);
    vec3 lightWorldDir = normalize((gbufferModelViewInverse * vec4(lightViewDir, 0.0)).xyz);
    vec3 sunWorldDir   = normalize((gbufferModelViewInverse * vec4(normalize(sunPosition), 0.0)).xyz);

    float sunElevation = sunWorldDir.y;
    float dayFactor    = smoothstep(-0.08, 0.16, sunElevation);
    float sunsetFactor = clamp(1.0 - abs(sunElevation) * 4.5, 0.0, 1.0);
    float rainDim      = 1.0 - rainStrength * 0.68;

    vec3 noonSunColor   = vec3(1.55, 1.42, 1.25);
    vec3 sunsetSunColor = vec3(1.85, 0.72, 0.28);
    vec3 nightMoonColor = vec3(0.16, 0.24, 0.42);
    vec3 directLightColor = mix(nightMoonColor, mix(noonSunColor, sunsetSunColor, sunsetFactor), dayFactor) * rainDim;

    vec3 skyColLinear = pow(skyColor, vec3(2.2));
    vec3 fogColLinear = pow(fogColor, vec3(2.2));
    float hemiWeight  = worldNormal.y * 0.35 + 0.65;
    vec3 skyAmbient   = mix(fogColLinear * 0.35 + vec3(0.03, 0.04, 0.06), skyColLinear * 0.55 + vec3(0.06, 0.08, 0.12), hemiWeight);
    skyAmbient       *= (0.12 + 0.88 * pow(lightmap.y, 1.65)) * mix(0.32, 1.0, dayFactor);

    vec3 caveAmbient = vec3(0.018, 0.020, 0.026);

    float torchLevel = lightmap.x;
#ifdef DYNAMIC_HANDLIGHT
    float heldLight = max(float(heldBlockLightValue), float(heldBlockLightValue2));
    if (heldLight > 0.0) {
        float handAtten = clamp(1.0 - viewDist / (heldLight * 1.15), 0.0, 1.0);
        torchLevel = max(torchLevel, handAtten * 0.92);
    }
#endif

    float flicker = 1.0;
#ifdef FLICKER_TORCH
    flicker = 0.96 + 0.04 * sin(frameTimeCounter * 7.5 + sin(frameTimeCounter * 19.0));
#endif
    float torchCurve = pow(clamp(torchLevel, 0.0, 1.0), 2.35) * flicker;
    vec3 torchLight  = vec3(1.65, 0.82, 0.32) * torchCurve * 1.35;

    float NdotL = max(dot(worldNormal, lightWorldDir), 0.0);
    bool isFoliage = (abs(matFlag - 0.25) < 0.05);

    float sssTerm = 0.0;
#ifdef FOLIAGE_SSS
    if (isFoliage) {
        vec3 viewWorldDir = normalize(worldPos);
        float backLight = pow(clamp(dot(viewWorldDir, -lightWorldDir), 0.0, 1.0), 3.0);
        sssTerm = (0.32 + 0.55 * backLight) * smoothstep(0.05, 0.75, lightmap.y);
        NdotL = max(NdotL, 0.38);
    }
#endif

    vec3 shadowVisibility = computePCSSShadow(
        shadowtex0,
        shadowtex1,
        shadowcolor0,
        worldPos,
        worldNormal,
        NdotL,
        lightmap.y,
        shadowModelView,
        shadowProjection,
        gl_FragCoord.xy,
        frameCounter
    );

    vec3 viewDirWorld = normalize(-worldPos);
    vec3 halfVec = normalize(lightWorldDir + viewDirWorld);
    float wetBoost = 0.22 + wetness * 0.45 * clamp(worldNormal.y, 0.0, 1.0);
    float specTerm = pow(max(dot(worldNormal, halfVec), 0.0), 32.0) * wetBoost * 0.35;

    vec3 directTerm = directLightColor * (NdotL + sssTerm * vec3(0.85, 1.15, 0.45)) * shadowVisibility;
    vec3 emissiveBoost = baseColor.rgb * (emissive * 2.8);

    vec3 litColor = baseColor.rgb * (caveAmbient + skyAmbient + torchLight + directTerm)
                  + directLightColor * shadowVisibility * specTerm
                  + emissiveBoost;

    outColor0 = vec4(max(litColor, vec3(0.0)), 1.0);
    outColor2 = vec4(0.95, lightmap.y, emissive, 1.0);
}
