import 'dart:math' as math;

/// Real 1D water surface simulation.
/// 48 coupled points, each feels:
///  - pull toward tilted baseline (gravity)
///  - pull toward neighbors (wave propagation)
///  - damping (energy loss)
///
/// This IS the wave equation. Not decorative sine waves.
class WaterSim {
  static const int N = 48;

  final List<double> pos = List.filled(N, 0.0);
  final List<double> vel = List.filled(N, 0.0);
  final List<double> accel = List.filled(N, 0.0);

  // Physics params (tuned for real water feel)
  static const double WAVE_K = 0.18;
  static const double TILT_K = 0.045;
  static const double DAMPING = 0.965;
  static const double MAX_POS = 55.0;
  static const double MAX_VEL = 12.0;

  double _smoothTilt = 0.0;

  void step(double dt, double tiltGx) {
    // Smooth sensor noise on tilt input
    _smoothTilt = _smoothTilt * 0.82 + tiltGx * 0.18;

    // Frame-rate normalisation (reference 60 Hz)
    final df = (dt * 60.0).clamp(0.0, 2.0);
    if (df < 0.01) return;

    const double center = N / 2;

    for (int i = 0; i < N; i++) {
      // Target height so surface forms a slope matching the tilt
      final target = _smoothTilt * 220.0 * (i - center) / N;

      // Spring toward tilted baseline
      accel[i] = (target - pos[i]) * TILT_K;

      // Neighbor coupling — this creates wave propagation
      if (i > 0 && i < N - 1) {
        final l = pos[i - 1] + pos[i + 1] - 2.0 * pos[i];
        accel[i] += l * WAVE_K;
      }
    }

    // Integrate (semi-implicit Euler)
    for (int i = 1; i < N - 1; i++) {
      vel[i] += accel[i] * df;
      vel[i] *= math.pow(DAMPING, df);
      pos[i] += vel[i] * df;

      if (pos[i] > MAX_POS) pos[i] = MAX_POS;
      if (pos[i] < -MAX_POS) pos[i] = -MAX_POS;
      if (vel[i] > MAX_VEL) vel[i] = MAX_VEL;
      if (vel[i] < -MAX_VEL) vel[i] = -MAX_VEL;
    }

    // Wall reflection (edges follow neighbors)
    pos[0] = pos[1];
    pos[N - 1] = pos[N - 2];
    vel[0] = vel[1] * 0.8;
    vel[N - 1] = vel[N - 2] * 0.8;
  }

  double get averageSlope {
    // (right end - left end) / N
    return (pos[N - 1] - pos[0]) / N;
  }

  double get energy {
    double s = 0;
    for (final v in vel) s += v * v;
    return math.sqrt(s / N);
  }
}
