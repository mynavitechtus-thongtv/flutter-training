import 'dart:io';

import 'package:dartx/dartx.dart';
import 'package:dio/dio.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:injectable/injectable.dart';

import '../../../../index.dart';

final appApiServiceProvider = Provider<AppApiService>(
  (ref) => getIt.get<AppApiService>(),
);

@LazySingleton()
class AppApiService {
  AppApiService(
    this._noneAuthAppServerApiClient,
    this._authAppServerApiClient,
    this._uploadFileServerApiClient,
  );

  final NoneAuthAppServerApiClient _noneAuthAppServerApiClient;
  final AuthAppServerApiClient _authAppServerApiClient;
  final UploadFileServerApiClient _uploadFileServerApiClient;

  Future<TokenAndRefreshTokenData> login({required String email, required String password}) async {
    final tokenAndRefreshTokenData = await _noneAuthAppServerApiClient
        .request<TokenAndRefreshTokenData, DataResponse<TokenAndRefreshTokenData>>(
      method: RestMethod.post,
      path: 'v1/login',
      body: {
        'email': email.trim(),
        'password': password,
      },
      decoder: (json) =>
          TokenAndRefreshTokenData.fromJson(json.safeCast<Map<String, dynamic>>() ?? {}),
    );
    return tokenAndRefreshTokenData?.data ?? const TokenAndRefreshTokenData();
  }

  Future<void> logout() async {
    await _authAppServerApiClient.request(
      method: RestMethod.post,
      path: 'v1/logout',
    );
  }

  Future<void> deleteAccount() async {
    await _authAppServerApiClient.request(
      method: RestMethod.delete,
      path: 'v1/me',
    );
  }

  Future<void> forgotPassword({
    required String email,
  }) async {
    await _noneAuthAppServerApiClient.request(
      method: RestMethod.post,
      path: 'v1/forgot-password/otp',
      body: {
        'email': email.trim(),
      },
    );
  }

  Future<void> resetPassword({
    required String email,
    required String otp,
    required String password,
    required String passwordConfirmation,
  }) async {
    await _noneAuthAppServerApiClient.request(
      method: RestMethod.post,
      path: 'v1/forgot-password',
      body: {
        'email': email.trim(),
        'otp': otp,
        'password': password,
        'password_confirmation': passwordConfirmation,
      },
    );
  }

  Future<void> changePassword({
    required String currentPassword,
    required String password,
    required String passwordConfirmation,
  }) async {
    await _authAppServerApiClient.request(
      method: RestMethod.post,
      path: 'v1/change-password',
      body: {
        'password': currentPassword,
        'new_password': password,
        'new_password_confirmation': passwordConfirmation,
      },
    );
  }

  Future<UserData> getMe() async {
    final response = await _authAppServerApiClient.request<UserData, DataResponse<UserData>>(
      method: RestMethod.get,
      path: 'v1/me',
      decoder: (json) => UserData.fromJson(json.safeCast<Map<String, dynamic>>() ?? {}),
    );

    return response?.data ?? const UserData();
  }

  Future<String?> getRedirectUrl(Uri uri) async {
    final response = await _noneAuthAppServerApiClient.fetch(RequestOptions(
      baseUrl: uri.toString(),
      followRedirects: false,
      validateStatus: (status) => status == HttpStatus.found,
    ));
    return response.headers.value(HttpHeaders.locationHeader);
  }

  Future<PreSignedUrlsData> _getPreSignedUrlsData({
    required String path,
    required int fileCount,
    required bool isMultiple,
  }) async {
    if (fileCount == 0) {
      return const PreSignedUrlsData();
    }
    if (isMultiple) {
      final response =
          await _authAppServerApiClient.request<PreSignedUrlsData, DataResponse<PreSignedUrlsData>>(
        method: RestMethod.get,
        path: path,
        queryParameters: {
          'number_of_images': fileCount,
          'image_count': fileCount,
        },
        successResponseDecoderType: SuccessResponseDecoderType.dataJsonObject,
        decoder: (json) => PreSignedUrlsData.fromJson(json.safeCast<Map<String, dynamic>>() ?? {}),
      );
      return response?.data ?? const PreSignedUrlsData();
    } else {
      final response =
          await _authAppServerApiClient.request<PreSignedItemData, DataResponse<PreSignedItemData>>(
        method: RestMethod.get,
        path: path,
        successResponseDecoderType: SuccessResponseDecoderType.dataJsonObject,
        decoder: (json) => PreSignedItemData.fromJson(json.safeCast<Map<String, dynamic>>() ?? {}),
      );
      return PreSignedUrlsData(presignedUrls: [response?.data ?? const PreSignedItemData()]);
    }
  }

  Future<PagingDataResponse<NotificationData>?> getNotifications({
    required int page,
    required int limit,
    bool? isRead,
  }) async {
    return _authAppServerApiClient.request<NotificationData, PagingDataResponse<NotificationData>>(
      method: RestMethod.get,
      path: 'v1/notifications',
      queryParameters: {
        'page': page,
        'limit': limit,
        if (isRead != null) 'is_read': isRead,
      },
      successResponseDecoderType: SuccessResponseDecoderType.paging,
      decoder: (json) => NotificationData.fromJson(json.safeCast<Map<String, dynamic>>() ?? {}),
    );
  }

  Future<PreSignedUrlsData> uploadFileToS3({
    required String path,
    required List<File> files,
    required Function(Map<String, String>) onSuccess,
    bool isMultiple = true,
  }) async {
    final preSignedUrlsData =
        await _getPreSignedUrlsData(path: path, fileCount: files.length, isMultiple: isMultiple);
    final convertedFiles = await Future.wait(
      files.map((file) => FileUtil.convertToWebPAndResize(inputFile: file)),
    );

    await Future.wait(preSignedUrlsData.presignedUrls.mapIndexed((i, e) async {
      final file = convertedFiles[i];

      try {
        final imageBytes = await file.readAsBytes();
        final options = Options(
          contentType: FileUtil.lookupMimeType(file.path),
          headers: {
            'Accept': '*/*',
            'Content-Length': imageBytes.length,
            'Connection': 'keep-alive',
            'User-Agent': 'ClinicPlush',
          },
        );
        await _uploadFileServerApiClient.request(
          method: RestMethod.put,
          path: e.url,
          body: imageBytes,
          options: options,
        );
      } catch (e) {
        Log.e('uploadFileToS3: $e');
        throw e;
      } finally {
        FileUtil.deleteFile(filePath: file.path);
      }
    }));
    onSuccess(preSignedUrlsData.presignedUrls
        .asMap()
        .map((index, item) => MapEntry(item.path, files[index].path)));

    return preSignedUrlsData;
  }
}
