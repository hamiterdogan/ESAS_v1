class SarfMalzemeTuru {
  final String ad;

  const SarfMalzemeTuru({required this.ad});

  factory SarfMalzemeTuru.fromJson(String value) {
    return SarfMalzemeTuru(ad: value);
  }

  @override
  String toString() => ad;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SarfMalzemeTuru &&
          runtimeType == other.runtimeType &&
          ad == other.ad;

  @override
  int get hashCode => ad.hashCode;
}
