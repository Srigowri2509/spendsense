class AdUnlockState {
  final int adsWatched;
  final DateTime? unlockExpiresAt;
  final String lockSessionId;

  AdUnlockState({
    required this.adsWatched,
    this.unlockExpiresAt,
    required this.lockSessionId,
  });

  Duration get totalUnlockDuration => Duration(minutes: 10 * adsWatched);

  bool get isActive =>
      unlockExpiresAt != null && unlockExpiresAt!.isAfter(DateTime.now());

  Map<String, dynamic> toJson() => {
        'adsWatched': adsWatched,
        'unlockExpiresAt': unlockExpiresAt?.millisecondsSinceEpoch,
        'lockSessionId': lockSessionId,
      };

  factory AdUnlockState.fromJson(Map<String, dynamic> json) {
    final expiresMs = json['unlockExpiresAt'];
    return AdUnlockState(
      adsWatched: json['adsWatched'] ?? 0,
      unlockExpiresAt: expiresMs != null
          ? DateTime.fromMillisecondsSinceEpoch(expiresMs)
          : null,
      lockSessionId: json['lockSessionId'] ?? '',
    );
  }

  AdUnlockState copyWith({
    int? adsWatched,
    DateTime? unlockExpiresAt,
    String? lockSessionId,
  }) {
    return AdUnlockState(
      adsWatched: adsWatched ?? this.adsWatched,
      unlockExpiresAt: unlockExpiresAt ?? this.unlockExpiresAt,
      lockSessionId: lockSessionId ?? this.lockSessionId,
    );
  }
}
