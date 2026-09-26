#version 460 core
#include <flutter/runtime_effect.glsl>

precision mediump float;

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
        mix(hash(i + vec2(0.0, 0.0)), hash(i + vec2(1.0, 0.0)), u.x),
        mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x),
        u.y
    );
}

float waveHeight(float x) {
    float nx = x / uSize.x;
    float h = 0.0;
    h += sin(nx * 6.28318 + uWavePhase * 1.0) * 0.50;
    h += sin(nx * 12.56636 - uWavePhase * 1.4) * 0.25;
    h += sin(nx * 25.13272 + uWavePhase * 0.85) * 0.12;
    h += sin(nx * 50.26544 - uWavePhase * 2.0) * 0.06;
    return h * uWaveEnergy * 18.0;
}

float waveSlope(float x) {
    float nx = x / uSize.x;
    float h = 0.0;
    h += cos(nx * 6.28318 + uWavePhase * 1.0) * 6.28318 * 0.50;
    h += cos(nx * 12.56636 - uWavePhase * 1.4) * 12.56636 * 0.25;
    h += cos(nx * 25.13272 + uWavePhase * 0.85) * 25.13272 * 0.12;
    h += cos(nx * 50.26544 - uWavePhase * 2.0) * 50.26544 * 0.06;
    return h * uWaveEnergy * 18.0 / uSize.x;
}

void main() {
    vec2 fc = FlutterFragCoord().xy;

    float baseY = uSize.y * 0.55;
    float dx = fc.x - uSize.x * 0.5;
    float sy = baseY + dx * tan(uSurfaceAngle)
               + uTiltY * 20.0 + waveHeight(fc.x);

    float below = fc.y - sy;

    if (below < 0.0) {
        fragColor = vec4(0.0, 0.0, 0.0, 0.0);
        return;
    }

    float depth = clamp(below / (uSize.y - sy + 1.0), 0.0, 1.0);
    float depthCurve = pow(depth, 0.65);

    vec3 shallowCol = vec3(0.42, 0.78, 0.90);
    vec3 midCol = vec3(0.13, 0.48, 0.68);
    vec3 deepCol = vec3(0.02, 0.13, 0.28);

    vec3 waterCol;
    if (depthCurve < 0.5) {
        waterCol = mix(shallowCol, midCol, depthCurve * 2.0);
    } else {
        waterCol = mix(midCol, deepCol, (depthCurve - 0.5) * 2.0);
    }

    // Caustics
    vec2 cUV = fc * 0.006;
    cUV.x += uTime * 0.08;
    cUV.y += uTime * 0.03;
    float c1 = noise(cUV);
    float c2 = noise(cUV * 2.1 + vec2(uTime * 0.05, -uTime * 0.04));
    float c3 = noise(cUV * 0.7 - vec2(uTime * 0.02, uTime * 0.06));
    float caustic = pow(c1 * c2 * c3 * 6.0, 1.8);
    caustic *= (1.0 - depthCurve * 0.7);
    waterCol += vec3(0.65, 0.88, 1.0) * caustic * 0.45;

    // Surface normal (analytic slope)
    float surfSlope = tan(uSurfaceAngle) + waveSlope(fc.x);
    float normalY = 1.0 / sqrt(1.0 + surfSlope * surfSlope);
    float fresnel = pow(1.0 - normalY, 4.0);

    waterCol = mix(waterCol, vec3(1.0, 0.55, 0.15), fresnel * 0.28);

    // Surface highlight line
    // Soft surface glow — layered
    float lineMask1 = exp(-pow(below / 8.0, 2.0));
    float lineMask2 = exp(-pow(below / 2.0, 2.0));
    waterCol = mix(waterCol, vec3(0.55, 0.85, 1.0), lineMask1 * 0.35);
    waterCol = mix(waterCol, vec3(0.95, 0.99, 1.0), lineMask2 * 0.55);

    // Moving specular glint
    float glintX = mod(uTime * 30.0 + uSize.x * 0.25, uSize.x * 1.4)
                   - uSize.x * 0.2;
    float gd = length(vec2(fc.x - glintX, (fc.y - sy) * 4.0));
    float glint = exp(-gd * gd * 0.0008) * exp(-below * 0.2);
    waterCol += vec3(1.0, 0.98, 0.95) * glint * 1.1;

    fragColor = vec4(waterCol, 1.0);
}
