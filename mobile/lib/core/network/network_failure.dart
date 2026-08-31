import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:luqa/app/app_config.dart';
import 'package:luqa/core/network/luqa_api_client.dart';
import 'package:luqa_api/api.dart' as api;

/// Turns a thrown failure into something worth putting on screen.
///
/// "Something went wrong" is the same sentence whether the phone lost the
/// port forward, the token expired, or the server is missing a route — three
/// problems with three different fixes. Naming which one it is costs nothing
/// and is the difference between a user retrying blindly and knowing what to
/// do next.
String describeNetworkFailure(Object error, {required String whileDoing}) {
  if (error is SessionExpiredException) {
    return 'Your session expired. Sign in again.';
  }

  if (error is TimeoutException) {
    return 'The server at ${AppConfig.apiBaseUrl} did not answer in time.';
  }

  // No route to the host at all: on a phone this is almost always a missing
  // `adb reverse tcp:3000 tcp:3000`, which does not survive a reconnect.
  if (error is http.ClientException) {
    return 'Cannot reach ${AppConfig.apiBaseUrl}.';
  }

  if (error is api.ApiException) {
    // The generated client turns every transport failure — connection
    // refused, DNS, TLS — into a synthetic 400 with the real cause attached.
    // Left alone it reads as "the server rejected your request" when in fact
    // nothing ever reached a server. The inner exception is what tells them
    // apart: a real rejection never has one.
    if (error.innerException != null) {
      return 'Cannot reach ${AppConfig.apiBaseUrl}. On a phone this usually '
          'means "adb reverse tcp:3000 tcp:3000" needs running again.';
    }

    if (error.code == 404) {
      return 'The server has no route for this yet ($whileDoing). '
          'It may be running an older build.';
    }
    // The server always says why in the body. Repeating only the status code
    // throws away the one piece of information that identifies the problem.
    final reason = _serverReason(error.message);
    if (error.code >= 500) {
      return 'The server errored while $whileDoing (${error.code})'
          '${reason == null ? '' : ': $reason'}.';
    }
    return 'The server rejected $whileDoing (${error.code})'
        '${reason == null ? '' : ': $reason'}.';
  }

  return 'Could not finish $whileDoing (${error.runtimeType}).';
}

/// Pulls `error.code` / `error.message` out of the API's error envelope.
/// Returns null for anything that is not shaped like one, so a stray HTML
/// error page never ends up quoted on screen.
String? _serverReason(String? body) {
  if (body == null || body.isEmpty || !body.trimLeft().startsWith('{')) {
    return null;
  }
  try {
    final decoded = jsonDecode(body);
    if (decoded is! Map<String, Object?>) return null;
    final detail = decoded['error'];
    if (detail is! Map<String, Object?>) return null;
    final code = detail['code'];
    final message = detail['message'];
    if (code is String && message is String) return '$message ($code)';
    return code is String ? code : (message is String ? message : null);
  } on Object {
    return null;
  }
}
