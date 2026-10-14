#include <flutter/runtime_effect.glsl>

// The engine supplies the input texture and its physical size.
uniform vec2 uTextureSize;
uniform sampler2D uBackdrop;
uniform vec2 uOrigin;
uniform vec2 uScale;
uniform vec2 uSize;
uniform float uPosition;
uniform float uStretch;
uniform float uPress;
uniform float uCount;
out vec4 fragColor;

float capsule(vec2 p, vec2 halfSize) {
  float radius = halfSize.y;
  vec2 q = abs(p) - halfSize + radius;
  return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - radius;
}

vec2 normalAt(vec2 p, vec2 halfSize) {
  vec2 q = abs(p) - halfSize + halfSize.y;
  // The flat part of a capsule has a vertical normal.
  vec2 n = max(q, 0.0);
  if (length(n) < 0.001) n = vec2(0.0, 1.0);
  return normalize(n) * sign(p + vec2(0.0001));
}

vec4 sampleBackdrop(vec2 pixel) {
  vec2 uv = clamp(pixel / uTextureSize, vec2(0.001), vec2(0.999));
#ifdef IMPELLER_TARGET_OPENGLES
  uv.y = 1.0 - uv.y;
#endif
  return texture(uBackdrop, uv);
}

void main() {
  vec2 pixel = FlutterFragCoord().xy;
  vec2 local = (pixel - uOrigin) / uScale;
  vec2 halfSize = uSize * 0.5;
  vec2 centered = local - halfSize;
  float outerDistance = capsule(centered, halfSize);
  vec2 outerNormal = normalAt(centered, halfSize);
  float edge = 1.0 - smoothstep(0.0, 12.0, -outerDistance);
  // Light bends most at the thick rim and remains clear in the centre.
  vec2 displacement = -outerNormal * edge * edge * 7.0;

  float cell = (uSize.x - 14.0) / uCount;
  vec2 lensCenter = vec2(7.0 + cell * (uPosition + 0.5), halfSize.y);
  vec2 lensHalf = vec2(cell * 0.5 * (1.0 + uStretch), 25.0);
  lensHalf *= 1.0 + uPress * 0.07;
  lensHalf.y *= 1.0 - uStretch * 0.3;
  vec2 lensPoint = local - lensCenter;
  float lensDistance = capsule(lensPoint, lensHalf);
  float inside = 1.0 - smoothstep(-0.7, 0.7, lensDistance);
  float lip = 1.0 - smoothstep(0.0, 10.0, -lensDistance);
  vec2 lensNormal = normalAt(lensPoint, lensHalf);
  displacement += inside * (-lensNormal * lip * lip * (5.5 + 3.0 * uPress)
                  - lensPoint * (0.055 + 0.025 * uPress));
  vec2 source = pixel + displacement * uScale;

  // A little frost keeps busy content legible without hiding the lens.
  vec2 frost = uScale * mix(1.15, 0.45, inside * uPress);
  vec4 color = sampleBackdrop(source) * 0.52;
  color += sampleBackdrop(source + vec2(frost.x, frost.y)) * 0.12;
  color += sampleBackdrop(source + vec2(-frost.x, frost.y)) * 0.12;
  color += sampleBackdrop(source + vec2(frost.x, -frost.y)) * 0.12;
  color += sampleBackdrop(source - frost) * 0.12;
  // Fine spectral separation only along the curved glass lip.
  vec2 fringe = (outerNormal * edge + lensNormal * lip * inside) * uScale * 0.38;
  color.r = mix(color.r, sampleBackdrop(source + fringe).r, 0.35);
  color.b = mix(color.b, sampleBackdrop(source - fringe).b, 0.35);
  fragColor = color;
}
