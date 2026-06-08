/// Service class for Cloudflare R2 file storage using the S3-compatible API.
///
/// Uploads and deletes files via direct HTTP requests to the R2 endpoint
/// using AWS Signature Version 4 signed headers. All uploaded files are
/// served through the custom domain [file.zaxo.eu.cc].
library;

import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

/// Provides file upload / delete operations against Cloudflare R2 storage.
///
/// R2 is S3-compatible, so we use the standard S3 `PUT` operation with
/// AWS Signature Version 4 (SigV4) for authentication.
///
/// ### Configuration
/// - **S3 API endpoint**: `https://704489378006d2bed6a45de180f6679f.r2.cloudflarestorage.com`
/// - **Bucket**: `zaxo`
/// - **Custom domain**: `file.zaxo.eu.cc` (used for public URLs)
class R2StorageService {
  // ── R2 Configuration ───────────────────────────────────────────────────

  /// Cloudflare account ID.
  static const String _accountId = '704489378006d2bed6a45de180f6679f';

  /// R2 bucket name.
  static const String _bucket = 'zaxo';

  /// R2 Access Key ID.
  static const String _accessKeyId = '09de0e28c851a7dce7e62db3297ce968';

  /// R2 Secret Access Key.
  static const String _secretAccessKey =
      'eeb5583044c61c192085a9c19312d48073d4c20e379d6fd79c7d7c7cad7173be';

  /// Custom domain for serving files publicly.
  static const String _customDomain = 'file.zaxo.eu.cc';

  /// S3-compatible API endpoint.
  static const String _s3Endpoint =
      'https://$_accountId.r2.cloudflarestorage.com';

  /// AWS region used for SigV4 signing (R2 uses `auto`).
  static const String _region = 'auto';

  /// S3 service name.
  static const String _service = 's3';

  // ── Instance ───────────────────────────────────────────────────────────

  R2StorageService({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;
  final _uuid = const Uuid();

  // ═══════════════════════════════════════════════════════════════════════
  //  PUBLIC API
  // ═══════════════════════════════════════════════════════════════════════

  /// Uploads an image file to R2.
  ///
  /// [file] – The local image file to upload.
  /// [path] – Destination path in the bucket (e.g. `images/avatars/user1.jpg`).
  ///
  /// Returns the public URL via the custom domain:
  /// `https://file.zaxo.eu.cc/{path}`
  Future<String> uploadImage(File file, String path) async {
    return _uploadFile(file, path, contentType: _inferContentType(file));
  }

  /// Uploads an arbitrary file to R2.
  ///
  /// [file] – The local file to upload.
  /// [path] – Destination path in the bucket.
  ///
  /// Returns the public URL via the custom domain.
  Future<String> uploadFile(File file, String path) async {
    return _uploadFile(file, path);
  }

  /// Deletes a file from R2 by its [path].
  ///
  /// Does not throw if the file does not exist (idempotent).
  Future<void> deleteFile(String path) async {
    try {
      final host = '$_accountId.r2.cloudflarestorage.com';
      final objectKey = '$_bucket/$path';
      final url = '$_s3Endpoint/$_bucket/$path';

      final now = _nowAmzFormat();
      final dateStamp = now.substring(0, 8);

      // Canonical request.
      final canonicalHeaders =
          'host:$host\nx-amz-content-sha256:${_sha256Hex('')}\nx-amz-date:$now\n';
      final signedHeaders = 'host;x-amz-content-sha256;x-amz-date';
      final canonicalRequest = [
        'DELETE',
        '/$_bucket/$path',
        '',
        canonicalHeaders,
        signedHeaders,
        _sha256Hex(''),
      ].join('\n');

      final authorization = _buildAuthorization(
        method: 'DELETE',
        objectKey: objectKey,
        canonicalHeaders: canonicalHeaders,
        signedHeaders: signedHeaders,
        canonicalRequest: canonicalRequest,
        dateStamp: dateStamp,
        now: now,
        payloadHash: _sha256Hex(''),
      );

      await _dio.delete(
        url,
        options: Options(
          headers: {
            'Host': host,
            'x-amz-date': now,
            'x-amz-content-sha256': _sha256Hex(''),
            'Authorization': authorization,
          },
          validateStatus: (status) =>
              status != null && (status == 204 || status == 404 || status == 200),
        ),
      );
    } on DioException catch (e) {
      // 404 is fine for delete — file already gone.
      if (e.response?.statusCode == 404) return;
      throw Exception('Failed to delete file from R2: ${e.message}');
    } catch (e) {
      throw Exception('Failed to delete file from R2: $e');
    }
  }

  /// Generates a unique path for a given folder and file extension.
  ///
  /// Example: `generatePath('images/avatars', '.jpg')` →
  /// `images/avatars/550e8400-e29b-41d4-a716-446655440000.jpg`
  String generatePath(String folder, String extension) {
    return '$folder/${_uuid.v4()}$extension';
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  PRIVATE HELPERS
  // ═══════════════════════════════════════════════════════════════════════

  Future<String> _uploadFile(
    File file,
    String path, {
    String? contentType,
  }) async {
    try {
      final fileBytes = await file.readAsBytes();
      final host = '$_accountId.r2.cloudflarestorage.com';
      final now = _nowAmzFormat();
      final dateStamp = now.substring(0, 8);
      final payloadHash = _sha256HexBytes(fileBytes);

      // Build canonical request.
      final canonicalHeaders =
          'content-length:${fileBytes.length}\nhost:$host\nx-amz-content-sha256:$payloadHash\nx-amz-date:$now\n';
      final signedHeaders =
          'content-length;host;x-amz-content-sha256;x-amz-date';
      final canonicalRequest = [
        'PUT',
        '/$_bucket/$path',
        '',
        canonicalHeaders,
        signedHeaders,
        payloadHash,
      ].join('\n');

      final authorization = _buildAuthorization(
        method: 'PUT',
        objectKey: '$_bucket/$path',
        canonicalHeaders: canonicalHeaders,
        signedHeaders: signedHeaders,
        canonicalRequest: canonicalRequest,
        dateStamp: dateStamp,
        now: now,
        payloadHash: payloadHash,
      );

      final url = '$_s3Endpoint/$_bucket/$path';
      await _dio.put(
        url,
        data: Stream.fromIterable(fileBytes.map((b) => [b])),
        options: Options(
          headers: {
            'Host': host,
            'Content-Length': fileBytes.length,
            'Content-Type':
                contentType ?? 'application/octet-stream',
            'x-amz-date': now,
            'x-amz-content-sha256': payloadHash,
            'Authorization': authorization,
          },
          validateStatus: (status) => status != null && status < 300,
        ),
      );

      return 'https://$_customDomain/$path';
    } on DioException catch (e) {
      throw Exception('Failed to upload file to R2: ${e.message}');
    } catch (e) {
      throw Exception('Failed to upload file to R2: $e');
    }
  }

  // ── AWS Signature Version 4 ────────────────────────────────────────────

  /// Builds the full `Authorization` header value for an S3 request.
  String _buildAuthorization({
    required String method,
    required String objectKey,
    required String canonicalHeaders,
    required String signedHeaders,
    required String canonicalRequest,
    required String dateStamp,
    required String now,
    required String payloadHash,
  }) {
    // 1. String to sign.
    final credentialScope = '$dateStamp/$_region/$_service/aws4_request';
    final stringToSign = [
      'AWS4-HMAC-SHA256',
      now,
      credentialScope,
      _sha256Hex(canonicalRequest),
    ].join('\n');

    // 2. Signing key.
    final signingKey = _deriveSigningKey(dateStamp);

    // 3. Signature.
    final signature = Hmac(sha256, signingKey)
        .convert(utf8.encode(stringToSign))
        .toString();

    return 'AWS4-HMAC-SHA256 Credential=$_accessKeyId/$credentialScope, '
        'SignedHeaders=$signedHeaders, '
        'Signature=$signature';
  }

  /// Derives the signing key from the secret key and date stamp.
  List<int> _deriveSigningKey(String dateStamp) {
    final kDate = Hmac(sha256, utf8.encode('AWS4$_secretAccessKey'))
        .convert(utf8.encode(dateStamp))
        .bytes;
    final kRegion =
        Hmac(sha256, kDate).convert(utf8.encode(_region)).bytes;
    final kService =
        Hmac(sha256, kRegion).convert(utf8.encode(_service)).bytes;
    final kSigning = Hmac(sha256, kService)
        .convert(utf8.encode('aws4_request'))
        .bytes;
    return kSigning;
  }

  // ── Utility ────────────────────────────────────────────────────────────

  /// Returns the current time in `YYYYMMDDTHHMMSSZ` format (ISO 8601 basic).
  String _nowAmzFormat() {
    final now = DateTime.now().toUtc();
    return '${now.year}'
        '${now.month.toString().padLeft(2, '0')}'
        '${now.day.toString().padLeft(2, '0')}'
        'T'
        '${now.hour.toString().padLeft(2, '0')}'
        '${now.minute.toString().padLeft(2, '0')}'
        '${now.second.toString().padLeft(2, '0')}'
        'Z';
  }

  /// SHA-256 hex digest of a UTF-8 string.
  String _sha256Hex(String data) {
    return sha256.convert(utf8.encode(data)).toString();
  }

  /// SHA-256 hex digest of raw bytes.
  String _sha256HexBytes(List<int> data) {
    return sha256.convert(data).toString();
  }

  /// Infers a MIME content type from the file extension.
  String _inferContentType(File file) {
    final extension = p.extension(file.path).toLowerCase();
    switch (extension) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.gif':
        return 'image/gif';
      case '.webp':
        return 'image/webp';
      case '.svg':
        return 'image/svg+xml';
      case '.mp4':
        return 'video/mp4';
      case '.webm':
        return 'video/webm';
      case '.mp3':
        return 'audio/mpeg';
      case '.ogg':
        return 'audio/ogg';
      case '.pdf':
        return 'application/pdf';
      case '.doc':
        return 'application/msword';
      case '.docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      default:
        return 'application/octet-stream';
    }
  }
}
