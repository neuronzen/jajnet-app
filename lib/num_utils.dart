/// Firestore থেকে আসা সংখ্যা int/double/String যাই হোক, নিরাপদে int বানায়।
/// `(x ?? 0) as int` এর বদলে এটা ব্যবহার করুন — মান 525.0 হলেও crash করবে না।
int asInt(dynamic v, [int fallback = 0]) {
  if (v is int) return v;
  if (v is num) return v.round();
  if (v is String) {
    final t = v.trim();
    return int.tryParse(t) ?? double.tryParse(t)?.round() ?? fallback;
  }
  return fallback;
}
