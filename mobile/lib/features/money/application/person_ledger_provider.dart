import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:luqa/features/money/application/money_sync_engine.dart';
import 'package:luqa/features/money/data/money_providers.dart';
import 'package:luqa/features/money/domain/money_models.dart';

/// One person's whole history with the user.
///
/// A read, not a controller: everything that writes to it goes through the
/// money controller, and this simply reloads. Watching the sync engine is what
/// makes the ledger catch up once a bill entered offline reaches the server.
final personLedgerProvider = FutureProvider.autoDispose
    .family<PersonLedger, String>((ref, personId) async {
      ref.watch(moneySyncEngineProvider.select((state) => state.rounds));
      final repository = ref.watch(moneyRepositoryProvider);
      return repository.loadLedger(personId);
    });
