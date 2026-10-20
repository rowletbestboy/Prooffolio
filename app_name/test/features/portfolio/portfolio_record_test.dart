import 'package:flutter_test/flutter_test.dart';
import 'package:app_name/features/portfolio/domain/portfolio_record.dart';

void main() {
  test('record type values round-trip from database', () {
    expect(PortfolioRecordType.values.map((type) => type.databaseValue), [
      'certification',
      'achievement',
    ]);
    expect(
      PortfolioRecordType.fromDatabase('achievement'),
      PortfolioRecordType.achievement,
    );
  });

  test('draft trims content and stays private by default', () {
    final fields = PortfolioRecordDraft(
      recordType: PortfolioRecordType.achievement,
      title: '  Community award  ',
    ).toDatabaseFields();

    expect(fields['title'], 'Community award');
    expect(fields['source'], isNull);
    expect(fields['description'], '');
    expect(fields['is_public'], isFalse);
  });

  test('record parses optional dates and source safely', () {
    final record = PortfolioRecord.fromJson({
      'id': 'record-1',
      'user_id': 'user-1',
      'record_type': 'certification',
      'title': 'Food safety certificate',
      'source': null,
      'description': null,
      'achieved_on': '2025-03-02',
      'expires_on': null,
      'is_public': false,
      'created_at': '2025-03-02T00:00:00Z',
      'updated_at': '2025-03-02T00:00:00Z',
    });

    expect(record.source, '');
    expect(record.description, '');
    expect(record.achievedOn, DateTime.utc(2025, 3, 2));
    expect(record.expiresOn, isNull);
    expect(record.isPublic, isFalse);
  });
}
