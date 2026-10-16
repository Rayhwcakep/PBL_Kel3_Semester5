import 'package:dio/dio.dart';

import '../../core/config/app_config.dart';
import '../models/api_exception.dart';

/// Pembungkus tipis di atas Dio agar konfigurasi HTTP terpusat di satu tempat.
class ApiClient {
  ApiClient({Dio? dio}) : _dio = dio ?? _buildDio();

  final Dio _dio;

  Dio get dio => _dio;

  static Dio _buildDio() {
    return Dio(
      BaseOptions(
        baseUrl: '${AppConfig.baseUrl}${AppConfig.apiPrefix}',
        connectTimeout: AppConfig.connectTimeout,
        receiveTimeout: AppConfig.receiveTimeout,
        headers: const {'Content-Type': 'application/json'},
        responseType: ResponseType.json,
      ),
    );
  }

  /// GET dan ubah balasan menjadi [Map].
  Future<Map<String, dynamic>> getJson(String path) async {
    return _guard(() async {
      final response = await _dio.get<dynamic>(path);
      return _asMap(response.data);
    });
  }

  /// POST JSON dan ubah balasan menjadi [Map].
  Future<Map<String, dynamic>> postJson(
    String path,
    Map<String, dynamic> body,
  ) async {
    return _guard(() async {
      final response = await _dio.post<dynamic>(path, data: body);
      return _asMap(response.data);
    });
  }

  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map) return data.cast<String, dynamic>();
    throw const ApiException('Format balasan server tidak dikenali.');
  }

  /// Menjalankan [action] dan menerjemahkan error Dio menjadi [ApiException].
  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on DioException catch (error) {
      throw ApiException(
        _messageFor(error),
        statusCode: error.response?.statusCode,
      );
    }
  }

  String _messageFor(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return 'Koneksi ke server timeout. Periksa jaringan dan alamat API.';
      case DioExceptionType.connectionError:
        return 'Tidak dapat terhubung ke server. Pastikan backend FastAPI berjalan.';
      case DioExceptionType.badResponse:
        final status = error.response?.statusCode;
        final detail = error.response?.data;
        if (detail is Map && detail['detail'] != null) {
          return detail['detail'].toString();
        }
        return 'Server membalas dengan status $status.';
      case DioExceptionType.cancel:
        return 'Permintaan dibatalkan.';
      case DioExceptionType.badCertificate:
        return 'Sertifikat server tidak valid.';
      case DioExceptionType.unknown:
        return 'Terjadi kesalahan tak terduga: ${error.message ?? '-'}';
    }
  }
}
