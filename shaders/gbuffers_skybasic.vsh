#version 330 compatibility

out vec4 vColor;
out float vIsStar;

void main() {
    vColor = gl_Color;
    vIsStar = (gl_Color.r == gl_Color.g && gl_Color.g == gl_Color.b && gl_Color.r > 0.0) ? 1.0 : 0.0;
    gl_Position = gl_ProjectionMatrix * (gl_ModelViewMatrix * gl_Vertex);
}
