import '../models/explain_response.dart';

/// Cache in-memory untuk penjelasan SHAP (`GET /players/{id}/explain`).
///
/// Meminta ulang penjelasan untuk pemain yang sama setiap kali layar dibuka
/// itu mahal, padahal jawaban backend jarang berubah dalam satu sesi. Cache
/// ini:
/// - menyimpan hasil sukses selama [ttl],
/// - menggabungkan permintaan yang sedang berjalan (in-flight) untuk id sama,
/// - membatasi jumlah entri agar memori tidak tumbuh tanpa batas.
///
/// Pakai [ExplainCache.shared] agar cache dipakai bersama oleh semua
/// `ScoutingRepository` di aplikasi.
class ExplainCache {
  ExplainCache({
    this.ttl = const Duration(minutes: 10),
    this.maxEntries = 200,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  /// Cache bersama lintas layar dan lintas instance repository.
  static final ExplainCache shared = ExplainCache();

  /// Lama hasil dianggap segar. Setelah lewat, data dimuat ulang.
  final Duration ttl;

  /// Jumlah maksimum pemain yang disimpan sebelum entri terlama dibuang.
  final int maxEntries;

  final DateTime Function() _now;
  final Map<String, _ExplainEntry> _entries = {};
  final Map<String, Future<PlayerExplain>> _inFlight = {};

  /// Jumlah pemain yang sedang tersimpan (untuk test/diagnostik).
  int get length => _entries.length;

  /// Mengambil penjelasan dari cache bila masih segar.
  ///
  /// Bila tidak ada, [load] dipanggil sekali. Permintaan lain untuk [playerId]
  /// yang datang saat pemuatan masih berjalan akan memakai future yang sama,
  /// sehingga backend tidak dipanggil berkali-kali.
  Future<PlayerExplain> load(
    String playerId,
    Future<PlayerExplain> Function() load,
  ) {
    final cached = _entries[playerId];
    if (cached != null && cached.isFresh(_now(), ttl)) {
      return Future.value(cached.value);
    }

    final running = _inFlight[playerId];
    if (running != null) return running;

    final generation = _generations[playerId] ?? 0;
    final future = load().then((explain) {
      // Abaikan hasil permintaan lama yang sudah dibatalkan lewat [invalidate].
      if ((_generations[playerId] ?? 0) == generation) {
        _store(playerId, explain);
      }
      return explain;
    });

    _inFlight[playerId] = future;
    return future.whenComplete(() {
      if (identical(_inFlight[playerId], future)) {
        _inFlight.remove(playerId);
      }
    });
  }

  /// Menghapus satu pemain agar permintaan berikutnya memuat data baru.
  void invalidate(String playerId) {
    _entries.remove(playerId);
    _inFlight.remove(playerId);
    _generations[playerId] = (_generations[playerId] ?? 0) + 1;
  }

  /// Menghapus seluruh isi cache.
  void clear() {
    _entries.clear();
    _inFlight.clear();
    _generations.clear();
  }

  final Map<String, int> _generations = {};

  void _store(String playerId, PlayerExplain explain) {
    if (!_entries.containsKey(playerId) && _entries.length >= maxEntries) {
      final oldest = _entries.entries.reduce(
        (a, b) => a.value.loadedAt.isBefore(b.value.loadedAt) ? a : b,
      );
      _entries.remove(oldest.key);
    }
    _entries[playerId] = _ExplainEntry(explain, _now());
  }
}

class _ExplainEntry {
  const _ExplainEntry(this.value, this.loadedAt);

  final PlayerExplain value;
  final DateTime loadedAt;

  bool isFresh(DateTime now, Duration ttl) => now.difference(loadedAt) < ttl;
}
