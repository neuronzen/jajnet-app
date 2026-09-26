#version 460 core
#include <flutter/runtime_effect.glsl>

precision highp float;

uniform vec2 uSize;
uniform float uTime;
uniform float uSurfaceAngle;
uniform float uWaveEnergy;
uniform float uWavePhase;
uniform float uTiltY;

out vec4 fragColor;

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(
        mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x),
        mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x),
        u.y);
}

void main() {
    vec2 fc = FlutterFragCoord().xy;
    float baseY = uSize.y * 0.55;
    float dx = fc.x - uSize.x * 0.5;
    float slope = tan(clamp(uSurfaceAngle, -0.9, 0.9));
    float nx = fc.x / uSize.x;
    float e = clamp(uWaveEnergy, 0.0, 1.5);

    // Waves: ambient (always) + excited (from shake/tilt)
    float wave = 0.0;
    wave += sin(nx * 6.283 + uTime * 0.55) * 9.0;
    wave += sin(nx * 12.566 - uTime * 0.42) * 4.5;
    wave += sin(nx * 21.0 + uTime * 0.80) * 2.2;
    wave += sin(nx * 8.0 + uWavePhase * 1.15) * 14.0 * e;
    wave += sin(nx * 17.0 - uWavePhase * 1.40) * 6.5 * e;
    wave += sin(nx * 32.0 + uWavePhase * 0.90) * 3.0 * e;

    float sy = baseY + dx * slope + wave + uTiltY * 18.0;

    // === ABOVE SURFACE — white / very light sky ===
    if (fc.y < sy) {
        float t = clamp(fc.y / max(sy, 1.0), 0.0, 1.0);
        vec3 top = mix(vec3(1.0, 1.0, 1.0),
                       vec3(0.87, 0.94, 0.99), t);
        fragColor = vec4(top, 1.0);
        return;
    }

    // === BELOW SURFACE — water ===
    float below = fc.y - sy;
    float depth = clamp(below / (uSize.y * 0.55), 0.0, 1.0);

    // Reference: light cyan at surface → mid blue → deep navy
    vec3 shallowCol = vec3(0.68, 0.88, 0.97);
    vec3 midCol     = vec3(0.30, 0.64, 0.86);
    vec3 deepCol    = vec3(0.06, 0.28, 0.52);

    vec3 waterCol;
    if (depth < 0.45) {
        waterCol = mix(shallowCol, midCol, depth / 0.45);
    } else {
        waterCol = mix(midCol, deepCol, (depth - 0.45) / 0.55);
    }

    // Caustic light patterns under surface
    float c1 = noise(fc * 0.006 + vec2(uTime * 0.05, uTime * 0.03));
    float c2 = noise(fc * 0.012 + vec2(-uTime * 0.04, uTime * 0.05));
    float caustic = pow(c1 * c2 * 3.5, 2.2);
    caustic *= (1.0 - depth * 0.6);
    waterCol += vec3(0.80, 0.94, 1.0) * caustic * 0.30;

    // Bubbles rising from bottom
    for (int i = 0; i < 10; i++) {
        float fi = float(i);
        float bx = uSize.x * fract(fi * 0.618 + 0.15)
                   + sin(uTime * 0.4 + fi * 1.7) * 18.0;
        float cycle = fract(uTime * 0.12 + fi * 0.10);
        float by = sy + 20.0 + (1.0 - cycle) * (uSize.y - sy - 20.0);
        float size = 2.0 + mod(fi, 4.0) * 1.5;

        float d = length(fc - vec2(bx, by));
        float outer = smoothstep(size + 1.2, size - 0.3, d);
        float inner = smoothstep(size - 0.8, size - 2.2, d);
        float bubble = (outer - inner) * (1.0 - depth * 0.4);

        waterCol = mix(waterCol, vec3(1.0), bubble * 0.70);
    }

    // Bright surface line (crisp white highlight)
    float lineMask = exp(-pow(below / 2.0, 2.0));
    waterCol = mix(waterCol, vec3(1.0), lineMask * 0.92);

    // Darker shadow just below surface (from reference)
    float darkMask = exp(-pow((below - 7.0) / 4.5, 2.0));
    waterCol = mix(waterCol, vec3(0.16, 0.40, 0.62), darkMask * 0.55);

    // Moving specular glint
    float glintX = mod(uTime * 45.0, uSize.x * 1.6) - uSize.x * 0.30;
    float gd = length(vec2(fc.x - glintX, (fc.y - sy) * 3.5));
    float glint = exp(-gd * gd * 0.0003) * exp(-below * 0.04);
    waterCol += vec3(1.0) * glint * 0.50;

    fragColor = vec4(waterCol, 1.0);
}
