import 'package:esquinita_core/esquinita_core.dart';
import 'package:test/test.dart';

void main() {
  group('uuidV7', () {
    test('has version 7, variant 10 and the timestamp first', () {
      final at = DateTime.utc(2026, 11, 17, 21, 30);
      final id = uuidV7(now: at);
      expect(isUuid(id), isTrue);
      expect(id[14], '7');
      expect('89ab'.contains(id[19]), isTrue);
      final ms = int.parse(id.replaceAll('-', '').substring(0, 12), radix: 16);
      expect(ms, at.millisecondsSinceEpoch);
    });

    test('later ids sort later and do not repeat', () {
      final a = uuidV7(now: DateTime.utc(2026, 1, 1));
      final b = uuidV7(now: DateTime.utc(2026, 1, 1, 0, 0, 0, 1));
      expect(a.compareTo(b), lessThan(0));
      expect({for (var i = 0; i < 1000; i++) uuidV7()}, hasLength(1000));
    });
  });

  group('SyncCommand', () {
    final cmd = SyncCommand(
      opId: uuidV7(),
      deviceId: uuidV7(),
      userId: uuidV7(),
      createdAt: DateTime.parse('2026-11-17T16:30:00-05:00'),
      type: SpikeOperation.type,
      payload: const SpikeOperation(note: 'Piña', amountCents: 650).toPayload(),
    );

    test('round-trips through JSON in UTC', () {
      final back = SyncCommand.fromJson(cmd.toJson());
      expect(back.toJson(), cmd.toJson());
      expect(back.createdAt, DateTime.utc(2026, 11, 17, 21, 30));
    });

    test('rejects malformed input', () {
      Map<String, Object?> without(String k) => cmd.toJson()..remove(k);
      for (final bad in <Object?>[
        null,
        'x',
        without('op_id'),
        {...cmd.toJson(), 'op_id': 'not-a-uuid'},
        {...cmd.toJson(), 'created_at': 'ayer'},
        without('payload'),
        {...cmd.toJson(), 'type': ''},
      ]) {
        expect(() => SyncCommand.fromJson(bad), throwsFormatException);
      }
    });
  });

  test('PushResult keeps the original status of a duplicate', () {
    const r = PushResult(
      'id',
      PushStatus.duplicate,
      originalStatus: PushStatus.rejected,
      message: 'note must be 1-200 characters',
    );
    final back = PushResult.fromJson(r.toJson());
    expect(back.status, PushStatus.duplicate);
    expect(back.originalStatus, PushStatus.rejected);
    expect(back.message, r.message);
  });

  test('SpikeOperation validates its payload', () {
    expect(
      SpikeOperation.fromPayload(const {'note': 'ok', 'amount_cents': 100})
          .amountCents,
      100,
    );
    for (final bad in const <Map<String, Object?>>[
      {'note': '', 'amount_cents': 1},
      {'note': 'ok', 'amount_cents': 1.5},
      {'note': 'ok'},
    ]) {
      expect(() => SpikeOperation.fromPayload(bad), throwsFormatException);
    }
  });
}
