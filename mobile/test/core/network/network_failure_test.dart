import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:luqa/core/network/network_failure.dart';
import 'package:luqa_api/api.dart' as api;

void main() {
  test('a transport failure is not reported as a server rejection', () {
    // The generated client wraps connection failures as a synthetic 400 with
    // the real cause attached. Reading that as "the server rejected your
    // request" sends the reader hunting for a bug in a request that was never
    // delivered, so the inner exception has to win over the status code.
    final failure = api.ApiException.withInner(
      HttpStatus.badRequest,
      'Socket operation failed: GET /time-entries',
      const SocketException('Connection refused'),
      StackTrace.empty,
    );

    final message = describeNetworkFailure(
      failure,
      whileDoing: 'loading the timeline',
    );

    expect(message, contains('Cannot reach'));
    expect(message, isNot(contains('rejected')));
    expect(message, isNot(contains('400')));
  });

  test('a genuine rejection quotes the server\'s own reason', () {
    final failure = api.ApiException(
      400,
      '{"error":{"code":"invalid_window","message":"Invalid from/to window"}}',
    );

    expect(
      describeNetworkFailure(failure, whileDoing: 'loading the timeline'),
      'The server rejected loading the timeline (400): '
      'Invalid from/to window (invalid_window).',
    );
  });

  test('a non-JSON error body is not quoted back at the reader', () {
    final failure = api.ApiException(
      500,
      '<!doctype html><title>Error</title>',
    );

    expect(
      describeNetworkFailure(failure, whileDoing: 'saving that block'),
      'The server errored while saving that block (500).',
    );
  });

  test('a timeout names the origin it waited on', () {
    expect(
      describeNetworkFailure(TimeoutException('x'), whileDoing: 'signing in'),
      contains('did not answer in time'),
    );
  });

  test('a bare client exception reads as unreachable', () {
    expect(
      describeNetworkFailure(
        http.ClientException('Connection closed'),
        whileDoing: 'signing in',
      ),
      contains('Cannot reach'),
    );
  });
}
