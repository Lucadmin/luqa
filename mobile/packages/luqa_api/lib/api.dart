//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

library openapi.api;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:http/http.dart';
import 'package:intl/intl.dart';
import 'package:meta/meta.dart';

part 'api_client.dart';
part 'api_helper.dart';
part 'api_exception.dart';
part 'auth/authentication.dart';
part 'auth/api_key_auth.dart';
part 'auth/oauth.dart';
part 'auth/http_basic_auth.dart';
part 'auth/http_bearer_auth.dart';
part 'optional.dart';

part 'api/authentication_api.dart';
part 'api/categories_api.dart';
part 'api/health_api.dart';
part 'api/time_entries_api.dart';

part 'model/category.dart';
part 'model/category_list_response.dart';
part 'model/category_response.dart';
part 'model/create_category_request.dart';
part 'model/create_session_request.dart';
part 'model/create_time_entry_request.dart';
part 'model/device_health_source.dart';
part 'model/entry_source.dart';
part 'model/error_detail.dart';
part 'model/error_response.dart';
part 'model/health_metric_type.dart';
part 'model/health_sample_import.dart';
part 'model/health_sample_ref.dart';
part 'model/health_sync_counts.dart';
part 'model/health_sync_request.dart';
part 'model/health_sync_response.dart';
part 'model/health_sync_state.dart';
part 'model/health_sync_state_list_response.dart';
part 'model/mobile_user.dart';
part 'model/refresh_session_request.dart';
part 'model/session_credentials.dart';
part 'model/sleep_session_import.dart';
part 'model/sleep_stage.dart';
part 'model/sleep_sync_payload.dart';
part 'model/sleep_sync_window.dart';
part 'model/time_entry.dart';
part 'model/time_entry_list_response.dart';
part 'model/time_entry_response.dart';

/// An [ApiClient] instance that uses the default values obtained from
/// the OpenAPI specification file.
var defaultApiClient = ApiClient();

const _delimiters = {'csv': ',', 'ssv': ' ', 'tsv': '\t', 'pipes': '|'};
const _dateEpochMarker = 'epoch';
const _deepEquality = DeepCollectionEquality();
final _dateFormatter = DateFormat('yyyy-MM-dd');
final _regList = RegExp(r'^List<(.*)>$');
final _regSet = RegExp(r'^Set<(.*)>$');
final _regMap = RegExp(r'^Map<String,(.*)>$');

bool _isEpochMarker(String? pattern) =>
    pattern == _dateEpochMarker || pattern == '/$_dateEpochMarker/';
