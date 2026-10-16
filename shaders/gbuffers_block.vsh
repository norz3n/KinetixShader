#version 330 compatibility

uniform mat4 gbufferModelViewInverse;

out vec2 vTexCoord;
out vec2 vLmCoord;
out vec4 vColor;
out vec3 vWorldNormal;

void main() {
    vTexCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    vLmCoord  = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
    vColor    = gl_Color;

    vec3 viewNormal = normalize(gl_NormalMatrix * gl_Normal);
    vWorldNormal = normalize((gbufferModelViewInverse * vec4(viewNormal, 0.0)).xyz);

    gl_Position = gl_ProjectionMatrix * (gl_ModelViewMatrix * gl_Vertex);
}
