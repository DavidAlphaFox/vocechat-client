import 'package:dio/dio.dart';
import 'package:vocechat_client/api/lib/dio_util.dart';
import 'package:vocechat_client/api/models/token/token_login_request.dart';
import 'package:vocechat_client/api/models/token/login_response.dart';
import 'package:vocechat_client/api/models/token/token_renew_response.dart';
import 'package:vocechat_client/api/models/token/token_renew_request.dart';
import 'package:vocechat_client/app.dart';

class TokenApi {
  late final String _baseUrl;

  TokenApi(String serverUrl) {
    _baseUrl = serverUrl + "/api/token";
  }

  /// Do login.
  ///
  /// Must use with referer in http header to fulfill certificate requirement.
  Future<Response<LoginResponse>> tokenLoginPost(TokenLoginRequest req) async {
    final dio = DioUtil(baseUrl: _baseUrl);

    // Special handling for Privoce dev.
    dio.options.headers = {'referer': App.app.chatServerM.fullUrl};
    if (App.app.chatServerM.url == "dev.voce.chat") {
      dio.options.headers = {'referer': "https://privoce.voce.chat"};
    }

    dio.options.validateStatus = (status) {
      return [200, 401, 403, 404, 409, 423, 451].contains(status);
    };

    final res = await dio.post("/login", data: req.toJson());

    var newRes = Response<LoginResponse>(
        headers: res.headers,
        requestOptions: res.requestOptions,
        isRedirect: res.isRedirect,
        statusCode: res.statusCode,
        statusMessage: res.statusMessage,
        redirects: res.redirects,
        extra: res.extra);

    if (res.statusCode == 200 && res.data != null) {
      final data = LoginResponse.fromJson(res.data!);
      newRes.data = data;
    }
    return newRes;
  }

  Future<Response<TokenRenewResponse>> tokenRenewPost(
      TokenRenewRequest req) async {
    final dio = DioUtil(baseUrl: _baseUrl);
    dio.options.validateStatus = (status) {
      // return status != null && status < 500;
      return [200, 401, 404].contains(status);
    };
    final res = await dio.post("/renew", data: req.toJson());

    var newRes = Response<TokenRenewResponse>(
        headers: res.headers,
        requestOptions: res.requestOptions,
        isRedirect: res.isRedirect,
        statusCode: res.statusCode,
        statusMessage: res.statusMessage,
        redirects: res.redirects,
        extra: res.extra);

    if (res.statusCode == 200 && res.data != null) {
      final data = TokenRenewResponse.fromJson(res.data!);
      newRes.data = data;
    }
    return newRes;
  }

  Future<Response> getLogout() async {
    final dio = DioUtil.token(baseUrl: _baseUrl);
    return await dio.get("/logout");
  }
}
