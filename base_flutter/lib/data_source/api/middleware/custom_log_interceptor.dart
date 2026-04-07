// ignore_for_file: avoid_nested_conditions, avoid_using_unsafe_cast, avoid_dynamic
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../index.dart';

class CustomLogInterceptor extends BaseInterceptor {
  CustomLogInterceptor() : super(InterceptorType.customLog);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kReleaseMode || !Config.enableLogInterceptor || !Config.enableLogRequestInfo) {
      handler.next(options);

      return;
    }

    final log = <String>[];
    log.add('************ Request ************');
    log.add('🌐 Request: ${options.method} ${options.uri}');
    if (options.headers.isNotEmpty) {
      log.add('🌐 Request Headers:');
      log.add('🌐 ${_prettyResponse(options.headers)}');
    }

    if (options.data != null) {
      log.add('🌐 Request Body:');
      if (options.data is FormData) {
        final data = options.data as FormData;
        if (data.fields.isNotEmpty) {
          log.add('🌐 Fields: ${_limitLines(text: _prettyResponse(data.fields))}');
        }
        if (data.files.isNotEmpty) {
          log.add(
            '🌐 Files: ${_limitLines(text: _prettyResponse(data.files.map((e) => MapEntry(e.key, 'File name: ${e.value.filename}, Content type: ${e.value.contentType}, Length: ${e.value.length}'))))}',
          );
        }
      } else {
        log.add('🌐 ${_limitLines(text: _prettyResponse(options.data))}');
      }
    }

    Log.d(log.join('\n'));
    handler.next(options);
  }

  @override
  void onResponse(Response<dynamic> response, ResponseInterceptorHandler handler) {
    if (kReleaseMode || !Config.enableLogInterceptor || !Config.enableLogSuccessResponse) {
      handler.next(response);

      return;
    }

    final log = <String>[];

    log.add('************ Request Response ************');
    log.add(
      '🎉 ${response.requestOptions.method} ${response.requestOptions.uri}',
    );
    log.add(
        '🎉 Response Body: ${_limitLines(text: _prettyResponse(response.requestOptions.data), maxLines: 100)}');
    log.add('🎉 Success Code: ${response.statusCode}');
    log.add('🎉 ${_limitLines(text: _prettyResponse(response.data), maxLines: 150)}');

    Log.d(log.join('\n'));
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kReleaseMode || !Config.enableLogInterceptor || !Config.enableLogErrorResponse) {
      handler.next(err);

      return;
    }

    final log = <String>[];

    log.add('************ Request Error ************');
    log.add('⛔️ ${err.requestOptions.method} ${err.requestOptions.uri}');
    log.add('⛔️ Error Code: ${err.response?.statusCode ?? 'unknown status code'}');
    log.add('⛔️ Json: ${err.response}');

    Log.e(log.join('\n'));
    handler.next(err);
  }

  // ignore: avoid-dynamic
  String _prettyResponse(dynamic data) {
    return Log.prettyJson(data);
  }

  String _limitLines({required String text, int maxLines = 150}) {
    final lines = text.split('\n');
    if (lines.length <= maxLines) {
      return text;
    }
    return '${lines.take(maxLines).join('\n')}\n... (truncated ${lines.length - maxLines} lines)';
  }
}
