#version 330 compatibility

#include "/lib/config.glsl"

uniform sampler2D colortex0;
uniform sampler2D colortex1;
uniform sampler2D colortex2;
uniform sampler2D depthtex0;
uniform sampler2D depthtex1;
uniform sampler2D shadowtex0;
uniform sampler2D shadowtex1;
uniform sampler2D shadowcolor0;

uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;
uniform mat4 shadowModelView;
uniform mat4 shadowProjection;

uniform vec3 cameraPosition;
uniform vec3 shadowLightPosition;
uniform vec3 sunPosition;
uniform vec3 skyColor;
uniform vec3 fogColor;

uniform float far;
uniform float rainStrength;
uniform float frameTimeCounter;
uniform int frameCounter;
uniform int isEyeInWater;
uniform int heldBlockLightValue;
uniform int heldBlockLightValue2;

in vec2 vTexCoord;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 outColor0;

#include "/lib/pcss.glsl"

vec3 getViewPos(vec2 uv, float d) {
    vec4 clip = vec4(uv * 2.0 - 1.0, d * 2.0 - 1.0, 1.0);
    vec4 view = gbufferProjectionInverse * clip;
    return view.xyz / view.w;
}

vec2 viewToScreenUV(vec3 viewPos) {
    vec4 clip = gbufferProjection * vec4(viewPos, 1.0);
    return (clip.xy / clip.w) * 0.5 + 0.5;
}

void main() {
    vec3 color = texture(colortex0, vTexCoord).rgb;
    float depth0 = texture(depthtex0, vTexCoord).r;

    vec3 skyColLin = pow(skyColor, vec3(2.2));
    vec3 fogColLin = pow(fogColor, vec3(2.2));

    vec3 lightViewDir  = normalize(shadowLightPosition);
    vec3 lightWorldDir = normalize((gbufferModelViewInverse * vec4(lightViewDir, 0.0)).xyz);
    vec3 sunWorldDir   = normalize((gbufferModelViewInverse * vec4(normalize(sunPosition), 0.0)).xyz);
    float dayFactor    = smoothstep(-0.08, 0.16, sunWorldDir.y);
    float sunsetFactor = clamp(1.0 - abs(sunWorldDir.y) * 4.5, 0.0, 1.0);
    float rainDim      = 1.0 - rainStrength * 0.68;

    vec3 directLightColor = mix(vec3(0.16, 0.24, 0.42), mix(vec3(1.55, 1.42, 1.25), vec3(1.85, 0.72, 0.28), sunsetFactor), dayFactor) * rainDim;

    if (depth0 < 0.999999) {
        vec4 packedNormLm = texture(colortex1, vTexCoord);
        vec4 matInfo      = texture(colortex2, vTexCoord);
        float matFlag     = matInfo.r;
        vec2 lightmap     = vec2(packedNormLm.z, matInfo.g);
        vec3 worldNormal  = decodeNormal(packedNormLm.xy);

        vec3 viewPos0  = getViewPos(vTexCoord, depth0);
        vec3 worldPos0 = (gbufferModelViewInverse * vec4(viewPos0, 1.0)).xyz;
        float viewDist = length(viewPos0);

        if (abs(matFlag - 0.75) < 0.05) {
            float depth1 = texture(depthtex1, vTexCoord).r;
            vec3 viewPos1 = getViewPos(vTexCoord, depth1);
            vec3 worldPos1 = (gbufferModelViewInverse * vec4(viewPos1, 1.0)).xyz;
            float waterDepth = max(length(viewPos1 - viewPos0), 0.0);

        #ifdef WATER_CAUSTICS
            if (depth1 < 0.999999 && waterDepth < 24.0) {
                float caustic = computeCaustics(worldPos1 + cameraPosition, frameTimeCounter);
                float depthAtten = exp(-waterDepth * 0.16) * lightmap.y;
                color += color * caustic * directLightColor * (depthAtten * 0.55);
            }
        #endif

            vec3 absorption = exp(-waterDepth * vec3(0.32, 0.10, 0.06));
            vec3 deepOceanColor = vec3(0.015, 0.11, 0.18) * (0.25 + 0.75 * dayFactor) * max(lightmap.y, 0.15);
            color = mix(deepOceanColor, color * absorption, clamp(exp(-waterDepth * 0.14), 0.08, 0.92));

            float NdotL = max(dot(worldNormal, lightWorldDir), 0.0);
            vec3 waterShadow = computePCSSShadow(
                shadowtex0, shadowtex1, shadowcolor0,
                worldPos0, worldNormal, max(NdotL, 0.35), lightmap.y,
                shadowModelView, shadowProjection, gl_FragCoord.xy, frameCounter
            );

        #ifdef WATER_CAUSTICS
            if (waterDepth > 0.001 && waterDepth < 0.42 && worldNormal.y > 0.7) {
                float foamWave = 0.5 + 0.5 * sin(dot((worldPos0 + cameraPosition).xz, vec2(4.5, 4.2)) - frameTimeCounter * 3.2);
                float foamMask = pow(1.0 - waterDepth / 0.42, 2.2) * (0.65 + 0.35 * foamWave) * WATER_FOAM_OPACITY;
                vec3 foamColor = (skyColLin * 0.5 + directLightColor * waterShadow * 0.5) * 0.85;
                color = mix(color, foamColor, clamp(foamMask, 0.0, 0.85));
            }
        #endif

            vec3 viewNormal = normalize(mat3(transpose(gbufferModelViewInverse)) * worldNormal);
            vec3 viewDir = normalize(viewPos0);
            float NdotV = max(dot(-viewDir, viewNormal), 0.0);
            float fresnel = 0.02 + 0.98 * pow(1.0 - NdotV, 4.0);

            vec3 reflWorldDir = reflect(normalize(worldPos0), worldNormal);
            vec3 reflectionColor = mix(fogColLin, skyColLin, clamp(reflWorldDir.y * 1.4, 0.0, 1.0)) * max(lightmap.y, 0.12);

            vec3 reflViewDir = reflect(viewDir, viewNormal);
            float sunGlint   = pow(max(dot(reflViewDir, lightViewDir), 0.0), 128.0) * 3.8;
            reflectionColor += directLightColor * waterShadow * sunGlint;

        #ifdef WATER_SSR
            vec3 rayStep = reflViewDir * max(viewDist * 0.14, 0.65);
            vec3 currPos = viewPos0 + rayStep * 0.5;
            for (int i = 0; i < 6; ++i) {
                currPos += rayStep;
                vec2 hitUV = viewToScreenUV(currPos);
                if (hitUV.x < 0.0 || hitUV.x > 1.0 || hitUV.y < 0.0 || hitUV.y > 1.0) {
                    break;
                }
                float sceneDepth = texture(depthtex1, hitUV).r;
                vec3 sceneViewPos = getViewPos(hitUV, sceneDepth);
                float depthDelta = sceneViewPos.z - currPos.z;
                if (depthDelta > 0.0 && depthDelta < length(rayStep) * 2.5) {
                    float edgeFade = smoothstep(0.0, 0.12, min(min(hitUV.x, 1.0 - hitUV.x), min(hitUV.y, 1.0 - hitUV.y)));
                    vec3 ssrSample = texture(colortex0, hitUV).rgb;
                    reflectionColor = mix(reflectionColor, ssrSample, edgeFade * 0.85);
                    break;
                }
                rayStep *= 1.45;
            }
        #endif

            color = mix(color, reflectionColor, clamp(fresnel * 0.82, 0.08, 0.88));
        }
        else if (matFlag < 0.85) {
            float NdotL = max(dot(worldNormal, lightWorldDir), 0.0);
            vec3 skyAmb = mix(fogColLin * 0.35, skyColLin * 0.55, worldNormal.y * 0.35 + 0.65)
                        * (0.15 + 0.85 * pow(lightmap.y, 1.65)) * mix(0.32, 1.0, dayFactor);

            float torchLevel = lightmap.x;
        #ifdef DYNAMIC_HANDLIGHT
            float heldLight = max(float(heldBlockLightValue), float(heldBlockLightValue2));
            if (heldLight > 0.0) {
                torchLevel = max(torchLevel, clamp(1.0 - viewDist / (heldLight * 1.15), 0.0, 1.0) * 0.92);
            }
        #endif
            vec3 torchLight = vec3(1.65, 0.82, 0.32) * pow(clamp(torchLevel, 0.0, 1.0), 2.35) * 1.35;
            vec3 totalLight = vec3(0.02) + skyAmb + torchLight + directLightColor * (NdotL * 0.75 + 0.25) * lightmap.y;
            color *= totalLight;
        }

        if (isEyeInWater == 1) {
            float waterFog = clamp(1.0 - exp(-viewDist * 0.065), 0.0, 0.92);
            vec3 deepWaterCol = vec3(0.015, 0.14, 0.22) * mix(0.25, 1.0, dayFactor);
            color = mix(color, deepWaterCol, waterFog);
        } else {
            float fogStart = far * 0.35;
            float distFog = clamp((viewDist - fogStart) / max(far - fogStart, 1.0), 0.0, 1.0);
            distFog = smoothstep(0.0, 1.0, distFog) * clamp(FOG_DENSITY * (0.45 + rainStrength * 0.45), 0.0, 1.0);
            vec3 atmosphereCol = mix(fogColLin, skyColLin, 0.35);
            color = mix(color, atmosphereCol, distFog);
        }
    }

#ifdef GODRAYS
    vec4 sunClip = gbufferProjection * vec4(sunPosition, 1.0);
    if (sunClip.w > 0.0 && isEyeInWater == 0) {
        vec2 sunUV = (sunClip.xy / sunClip.w) * 0.5 + 0.5;
        vec2 deltaUV = (sunUV - vTexCoord);
        float distToSun = length(deltaUV);
        float sunMask = exp(-distToSun * 2.4) * clamp(sunClip.z / sunClip.w, 0.0, 1.0) * rainDim;

        if (sunMask > 0.015) {
            float dither = interleavedGradientNoise(gl_FragCoord.xy, frameCounter);
            vec2 stepUV = deltaUV * (1.0 / 6.0);
            vec2 sampleUV = vTexCoord + stepUV * dither;
            float shaftAccum = 0.0;

            for (int i = 0; i < 6; ++i) {
                float sDepth = texture(depthtex0, clamp(sampleUV, 0.001, 0.999)).r;
                shaftAccum += (sDepth >= 0.9999) ? 1.0 : 0.0;
                sampleUV += stepUV;
            }
            shaftAccum /= 6.0;
            vec3 shaftColor = mix(fogColLin, vec3(1.4, 1.05, 0.65), 0.65);
            color += shaftColor * (shaftAccum * sunMask * 0.28);
        }
    }
#endif

    outColor0 = vec4(max(color, vec3(0.0)), 1.0);
}
