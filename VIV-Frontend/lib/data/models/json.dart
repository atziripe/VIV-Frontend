/// Tolerant JSON readers. The backend omits empty fields (`omitempty`) and
/// sometimes sends numbers as strings, so every read has a safe fallback.
typedef Json = Map<String, dynamic>;

extension JsonRead on Json {
  String? str(String key) {
    final v = this[key];
    if (v == null) return null;
    final s = v.toString();
    return s.isEmpty ? null : s;
  }

  String strOr(String key, [String fallback = '']) => str(key) ?? fallback;

  int? integer(String key) {
    final v = this[key];
    return switch (v) {
      int i => i,
      num n => n.toInt(),
      String s => int.tryParse(s),
      _ => null,
    };
  }

  double? number(String key) {
    final v = this[key];
    return switch (v) {
      num n => n.toDouble(),
      String s => double.tryParse(s),
      _ => null,
    };
  }

  bool flag(String key) {
    final v = this[key];
    return v == true || v == 1 || v == 'true';
  }

  Json? obj(String key) {
    final v = this[key];
    return v is Map ? v.cast<String, dynamic>() : null;
  }

  List<T> list<T>(String key, T Function(Json) parse) {
    final v = this[key];
    if (v is! List) return const [];
    return [
      for (final e in v)
        if (e is Map) parse(e.cast<String, dynamic>()),
    ];
  }

  List<String> strings(String key) {
    final v = this[key];
    if (v is! List) return const [];
    return [for (final e in v) e.toString()];
  }
}

/// Drops null entries so requests only carry fields the user actually set
/// (important for `PATCH /me`, where omitted means "leave unchanged").
Json compact(Json m) => {
  for (final e in m.entries)
    if (e.value != null) e.key: e.value,
};
