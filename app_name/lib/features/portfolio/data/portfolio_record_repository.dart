import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/portfolio_record.dart';

abstract interface class PortfolioRecordRepository {
  Future<List<PortfolioRecord>> listRecords(PortfolioRecordType type);
  Future<PortfolioRecord> createRecord(PortfolioRecordDraft draft);
  Future<PortfolioRecord> updateRecord(String id, PortfolioRecordDraft draft);
  Future<void> deleteRecord(String id);
}

class SupabasePortfolioRecordRepository implements PortfolioRecordRepository {
  SupabasePortfolioRecordRepository(this._client);

  final SupabaseClient _client;

  String get _userId {
    final id = _client.auth.currentUser?.id;
    if (id == null) throw const AuthException('Please sign in again.');
    return id;
  }

  @override
  Future<List<PortfolioRecord>> listRecords(PortfolioRecordType type) async {
    final rows = await _client
        .from('portfolio_records')
        .select()
        .eq('user_id', _userId)
        .eq('record_type', type.databaseValue)
        .order('updated_at', ascending: false);
    return rows
        .map((row) => PortfolioRecord.fromJson(row))
        .toList(growable: false);
  }

  @override
  Future<PortfolioRecord> createRecord(PortfolioRecordDraft draft) async {
    final row = await _client
        .from('portfolio_records')
        .insert({...draft.toDatabaseFields(), 'user_id': _userId})
        .select()
        .single();
    return PortfolioRecord.fromJson(row);
  }

  @override
  Future<PortfolioRecord> updateRecord(
    String id,
    PortfolioRecordDraft draft,
  ) async {
    final row = await _client
        .from('portfolio_records')
        .update({
          ...draft.toDatabaseFields(),
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('user_id', _userId)
        .eq('id', id)
        .select()
        .single();
    return PortfolioRecord.fromJson(row);
  }

  @override
  Future<void> deleteRecord(String id) async {
    final rows = await _client
        .from('portfolio_records')
        .delete()
        .eq('user_id', _userId)
        .eq('id', id)
        .select('id');
    if (rows.isEmpty) {
      throw StateError('Portfolio record could not be deleted.');
    }
  }
}
