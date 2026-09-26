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
    return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x),
               mix(hash(i + vec2(0.0, 1.0)),
                   hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

void main() {
    vec2 fc = FlutterFragCoord().xy;
    float baseY = uSize.y * 0.55;
    float dx = fc.x - uSize.x * 0.5;
    float slope = tan(clamp(uSurfaceAngle, -0.9, 0.9));
    float nx = fc.x / uSize.x;
    float e = clamp(uWaveEnergy, 0.0, 1.5);

    // Wave equation (multi-frequency)
    float wave = 0.0;
    wave += sin(nx * 6.283 + uTime * 0.55) * 8.0;
    wave += sin(nx * 12.566 - uTime * 0.42) * 4.0;
    wave += sin(nx * 21.0 + uTime * 0.80) * 1.8;
    // Excited waves from shake/tilt
    wave += sin(nx * 8.0 + uWavePhase * 1.15) * 18.0 * e;
    wave += sin(nx * 17.0 - uWavePhase * 1.40) * 8.0 * e;
    wave += sin(nx * 32.0 + uWavePhase * 0.90) * 3.5 * e;

    float sy = baseY + dx * slope + wave + uTiltY * 15.0;

    // === ABOVE SURFACE: soft white ===
    if (fc.y < sy) {
        float t = clamp(fc.y / max(sy, 1.0), 0.0, 1.0);
        vec3 above = mix(vec3(1.0), vec3(0.90, 0.95, 0.99), t);
        fragColor = vec4(above, 1.0);
        return;
    }

    // === BELOW SURFACE: reference-color water ===
    float below = fc.y - sy;
    float depth = clamp(below / (uSize.y * 0.55), 0.0, 1.0);

    // Reference colors: pale cyan → soft blue → deeper blue
    vec3 c1 = vec3(0.82, 0.94, 0.98);   // near surface (very light)
    vec3 c2 = vec3(0.55, 0.80, 0.92);   // mid (sky blue)
    vec3 c3 = vec3(0.25, 0.55, 0.78);   // deeper (soft ocean blue)

    vec3 waterCol;
    if (depth < 0.35) {
        waterCol = mix(c1, c2, depth / 0.35);
    } else {
        waterCol = mix(c2, c3, (depth - 0.35) / 0.65);
    }

    // Underwater caustics — soft light patterns
    float cA = noise(fc * 0.005 + vec2(uTime * 0.04, uTime * 0.02));
    float cB = noise(fc * 0.010 + vec2(-uTime * 0.03, uTime * 0.04));
    float caustic = pow(cA * cB * 4.0, 2.0) * (1.0 - depth * 0.55);
    waterCol += vec3(0.9, 0.98, 1.0) * caustic * 0.40;

    // Rising bubbles
    for (int i = 0; i < 8; i++) {
        float fi = float(i);
        float bx = uSize.x * fract(fi * 0.618 + 0.15) +
                   sin(uTime * 0.4 + fi * 1.7) * 15.0;
        float cycle = fract(uTime * 0.10 + fi * 0.12);
        float by = sy + 15.0 + (1.0 - cycle) * (uSize.y - sy - 15.0);
        float size = 1.8 + mod(fi, 4.0) * 1.2;
        float d = length(fc - vec2(bx, by));
        float outer = smoothstep(size + 1.0, size - 0.2, d);
        float inner = smoothstep(size - 0.6, size - 1.8, d);
        float bubble = (outer - inner) * (1.0 - depth * 0.3);
        waterCol = mix(waterCol, vec3(1.0), bubble * 0.65);
    }

    // Surface line — crisp white with soft glow
    float lineCore = exp(-pow(below / 1.6, 2.0));
    float lineGlow = exp(-pow(below / 5.0, 2.0));
    waterCol = mix(waterCol, vec3(1.0, 1.0, 1.0), lineGlow * 0.30);
    waterCol = mix(waterCol, vec3(1.0, 1.0, 1.0), lineCore * 0.85);

    // Dark edge just below surface (signature of real water)
    float edgeMask = exp(-pow((below - 5.0) / 3.0, 2.0));
    waterCol = mix(waterCol, vec3(0.45, 0.72, 0.88), edgeMask * 0.35);

    // Specular glints moving on surface
    float glintX = mod(uTime * 50.0, uSize.x * 1.5) - uSize.x * 0.25;
    float gd = length(vec2(fc.x - glintX, (fc.y - sy) * 4.0));
    float glint = exp(-gd * gd * 0.0004) * exp(-below * 0.08);
    waterCol += vec3(1.0) * glint * 0.60;

    fragColor = vec4(waterCol, 1.0);
}
