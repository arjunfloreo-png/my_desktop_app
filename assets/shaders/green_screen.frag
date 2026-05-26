// #version 320 es
// precision mediump float;

// uniform sampler2D uTexture;
// varying vec2 vUv;

void main() {
  vec4 color = texture(uTexture, vUv);
  
  // Remove green (G > 0.8, R < 0.3, B < 0.3)
  if (color.g > 0.8 && color.r < 0.3 && color.b < 0.3) {
    color.a = 0.0; // transparent
  }
  
  gl_FragColor = color;
}