/// Filter dan paginasi untuk `GET /players`.
///
/// Nama parameter mengikuti backend (`app/api/routes/players.py`) supaya
/// filter bisa langsung diteruskan sebagai query string.
class PlayerQuery {
  const PlayerQuery({
    this.archetype,
    this.league,
    this.minAge,
    this.maxAge,
    this.maxValueEur,
    this.search,
    this.offset,
    this.limit,
  });

  /// Kode arketipe, mis. `ST`, `CB`, `GK`.
  final String? archetype;

  /// Nama liga (dicocokkan sebagian oleh backend).
  final String? league;

  final int? minAge;
  final int? maxAge;

  /// Batas nilai pasar dalam Euro (bukan juta).
  final double? maxValueEur;

  /// Cari sebagian nama pemain atau klub.
  final String? search;

  final int? offset;
  final int? limit;

  /// `true` bila tidak ada filter yang aktif.
  bool get isEmpty =>
      archetype == null &&
      league == null &&
      minAge == null &&
      maxAge == null &&
      maxValueEur == null &&
      search == null &&
      offset == null &&
      limit == null;

  /// Query string untuk `GET /players`; entri kosong dibuang oleh [ApiClient].
  Map<String, dynamic> toQuery() => {
    'archetype': archetype,
    'league': league,
    'min_age': minAge,
    'max_age': maxAge,
    'max_value_eur': maxValueEur,
    'search': search,
    'offset': offset,
    'limit': limit,
  };

  PlayerQuery copyWith({
    String? league,
    bool clearLeague = false,
    int? maxAge,
    bool clearMaxAge = false,
    double? maxValueEur,
    bool clearMaxValue = false,
    String? search,
    bool clearSearch = false,
  }) {
    return PlayerQuery(
      archetype: archetype,
      league: clearLeague ? null : (league ?? this.league),
      minAge: minAge,
      maxAge: clearMaxAge ? null : (maxAge ?? this.maxAge),
      maxValueEur: clearMaxValue ? null : (maxValueEur ?? this.maxValueEur),
      search: clearSearch ? null : (search ?? this.search),
      offset: offset,
      limit: limit,
    );
  }
}
