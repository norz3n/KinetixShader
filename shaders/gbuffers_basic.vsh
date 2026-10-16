#version 330 compatibility

out vec4 vColor;

void main() {
    vColor = gl_Color;
    gl_Position = gl_ProjectionMatrix * (gl_ModelViewMatrix * gl_Vertex);
}
