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
part 'api/gym_api.dart';
part 'api/health_api.dart';
part 'api/money_api.dart';
part 'api/sleep_api.dart';
part 'api/time_entries_api.dart';

part 'model/category.dart';
part 'model/category_list_response.dart';
part 'model/category_response.dart';
part 'model/create_category_request.dart';
part 'model/create_expense_request.dart';
part 'model/create_group_request.dart';
part 'model/create_gym_location_request.dart';
part 'model/create_gym_session_request.dart';
part 'model/create_person_request.dart';
part 'model/create_session_request.dart';
part 'model/create_settlement_request.dart';
part 'model/create_time_entry_request.dart';
part 'model/delete_person_response.dart';
part 'model/device_health_source.dart';
part 'model/entry_source.dart';
part 'model/error_detail.dart';
part 'model/error_response.dart';
part 'model/expense.dart';
part 'model/expense_list_response.dart';
part 'model/expense_participant_input.dart';
part 'model/expense_response.dart';
part 'model/expense_share.dart';
part 'model/group_list_response.dart';
part 'model/group_response.dart';
part 'model/gym_exercise.dart';
part 'model/gym_exercise_history.dart';
part 'model/gym_exercise_history_response.dart';
part 'model/gym_exercise_point.dart';
part 'model/gym_exercise_reference.dart';
part 'model/gym_location.dart';
part 'model/gym_location_response.dart';
part 'model/gym_overview.dart';
part 'model/gym_overview_response.dart';
part 'model/gym_session.dart';
part 'model/gym_session_exercise.dart';
part 'model/gym_session_exercise_input.dart';
part 'model/gym_session_list_response.dart';
part 'model/gym_session_response.dart';
part 'model/gym_set.dart';
part 'model/gym_set_input.dart';
part 'model/health_metric_type.dart';
part 'model/health_sample_import.dart';
part 'model/health_sample_ref.dart';
part 'model/health_sync_counts.dart';
part 'model/health_sync_request.dart';
part 'model/health_sync_response.dart';
part 'model/health_sync_state.dart';
part 'model/health_sync_state_list_response.dart';
part 'model/ledger_item.dart';
part 'model/mobile_user.dart';
part 'model/money_overview.dart';
part 'model/money_overview_response.dart';
part 'model/person.dart';
part 'model/person_balance.dart';
part 'model/person_group.dart';
part 'model/person_ledger.dart';
part 'model/person_ledger_response.dart';
part 'model/person_list_response.dart';
part 'model/person_response.dart';
part 'model/refresh_session_request.dart';
part 'model/session_credentials.dart';
part 'model/settlement.dart';
part 'model/settlement_direction.dart';
part 'model/settlement_list_response.dart';
part 'model/settlement_response.dart';
part 'model/sleep_entry.dart';
part 'model/sleep_entry_list_response.dart';
part 'model/sleep_session_import.dart';
part 'model/sleep_source.dart';
part 'model/sleep_stage.dart';
part 'model/sleep_sync_payload.dart';
part 'model/sleep_sync_window.dart';
part 'model/split_mode.dart';
part 'model/time_entry.dart';
part 'model/time_entry_list_response.dart';
part 'model/time_entry_response.dart';
part 'model/update_expense_request.dart';
part 'model/update_group_request.dart';
part 'model/update_gym_location_request.dart';
part 'model/update_gym_session_request.dart';
part 'model/update_person_request.dart';
part 'model/update_settlement_request.dart';
part 'model/update_time_entry_request.dart';

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
