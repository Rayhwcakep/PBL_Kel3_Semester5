/// Pembaca nilai JSON balasan FastAPI.
///
/// Balasan backend memakai `null`, angka bulat, atau kolom opsional, jadi
/// konversi dikumpulkan di satu tempat agar model tidak mengulang logika yang
/// sama.
library;

/// Mengubah objek JSON menjadi [Map]. Kosong bila bentuknya lain.
Map<String, dynamic> asJsonMap(Object? value) {
  if (value is Map) return value.cast<String, dynamic>();
  return const {};
}

/// Mengubah daftar JSON menjadi [List] berisi [Map], melewati entri lain.
List<Map<String, dynamic>> asJsonList(Object? value) {
  if (value is! List) return const [];
  return [
    for (final item in value)
      if (item is Map) item.cast<String, dynamic>(),
  ];
}

/// Angka JSON menjadi [double]. Nilai kosong dihitung 0.
double asDouble(Object? value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0;
  return 0;
}

/// Angka JSON menjadi [int]. Nilai kosong dihitung 0.
int asInt(Object? value) {
  if (value is num) return value.round();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

/// Teks JSON. Nilai lain menjadi string kosong.
String asString(Object? value) => value is String ? value : '';

/// Peta `kunci: angka`, mis. `target_percentiles` atau `needs`.
Map<String, double> asNumberMap(Object? value) {
  final map = <String, double>{};
  for (final entry in asJsonMap(value).entries) {
    map[entry.key] = asDouble(entry.value);
  }
  return map;
}

/// Peta `kunci: teks`, mis. `context_labels`.
Map<String, String> asStringMap(Object? value) {
  final map = <String, String>{};
  for (final entry in asJsonMap(value).entries) {
    final text = asString(entry.value);
    if (text.isNotEmpty) map[entry.key] = text;
  }
  return map;
}
