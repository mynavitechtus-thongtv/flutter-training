// ignore_for_file: avoid_dynamic
import 'package:injectable/injectable.dart';

import '../../../../index.dart';

@Injectable()
class JsonObjectErrorResponseDecoder extends BaseErrorResponseDecoder<Map<String, dynamic>> {
  @override
  ServerError mapToServerError(Map<String, dynamic>? data) {
    return ServerError(
      generalServerErrorId:
          safeCast<String>(data?['error']?['error_code']) ?? safeCast<String>(data?['error_code']),
      generalMessage:
          safeCast<String>(data?['error']?['message']) ?? safeCast<String>(data?['message']),
      generalServerStatusCode:
          safeCast<int>(data?['error']?['status_code']) ?? safeCast<int>(data?['status_code']),
      time: safeCast<String>(data?['time']),
      errors: (safeCast<List<dynamic>>(data?['error']?['errors']) ??
                  safeCast<List<dynamic>>(data?['errors']))
              ?.map((jsonObject) => ServerErrorDetail(
                    field: safeCast<String>(jsonObject['field']),
                    serverErrorId: safeCast<String>(jsonObject['code']),
                    message: safeCast<String>(jsonObject['message']),
                  ))
              .toList(growable: false) ??
          [],
    );
  }
}
