import 'package:postgres/postgres.dart';

/// Thrown when all ten barcode digits (0-9) are taken.
class NoBarcodeDigitLeft implements Exception {}

/// Registers the device of a session (docs/modelo-datos.md §2.9): the server
/// hands out its series (`T1`, `P1`…) and barcode digit, so two devices can
/// never get the same ones, and creates its document series.
class DeviceService {
  /// Uses [_db].
  DeviceService(this._db);

  final SessionExecutor _db;

  /// Series letter per platform: T for the tablet (and phones), P for PCs.
  static const seriesLetter = {'android': 'T', 'windows': 'P'};

  /// The series each device numbers on its own, also offline.
  static const docTypes = ['sale', 'order_note', 'barcode'];

  /// Registers [deviceId] and returns it with `created: true`; a device that
  /// is already registered (the app retried) comes back as it was, with
  /// `created: false`. Series and digits of deactivated devices are never
  /// reused: documents and barcodes with them already exist.
  Future<({Map<String, Object?> device, bool created})> register({
    required String deviceId,
    required String name,
    required String platform,
    required String userId,
  }) => _db.runTx((tx) async {
    // One registration at a time, so two never pick the same series.
    await tx.execute('lock table devices in share row exclusive mode');
    final existing = await _read(tx, deviceId);
    if (existing != null) return (device: existing, created: false);

    final letter = seriesLetter[platform]!;
    final next =
        (await tx.execute(
              Sql.named('''
                select coalesce(max(substr(series_prefix, 2)::int), 0) + 1
                from devices where series_prefix like @l:text || '%' '''),
              parameters: {'l': letter},
            )).single[0]!
            as int;
    final digits = await tx.execute(
      'select d from generate_series(0, 9) d '
      'where d not in (select barcode_digit from devices) order by d limit 1',
    );
    if (digits.isEmpty) throw NoBarcodeDigitLeft();

    await tx.execute(
      Sql.named('''
        insert into devices (id, name, platform, series_prefix, barcode_digit,
                             version)
        values (@id:uuid, @name:text, @p:text, @s:text, @d:int4, 0)'''),
      parameters: {
        'id': deviceId,
        'name': name,
        'p': platform,
        's': '$letter$next',
        'd': digits.single[0],
      },
    );
    for (final t in docTypes) {
      await tx.execute(
        Sql.named(
          'insert into document_series (device_id, doc_type) '
          'values (@id:uuid, @t:text)',
        ),
        parameters: {'id': deviceId, 't': t},
      );
    }
    // The first tablet becomes the backup cash device (§3.4) until the
    // Administrador picks another one.
    if (platform == 'android') {
      await tx.execute(
        Sql.named('''
          update settings set value = to_jsonb(@id:text)
          where key = 'cash.backup_device_id' and value = 'null' '''),
        parameters: {'id': deviceId},
      );
    }
    final device = (await _read(tx, deviceId))!;
    await tx.execute(
      Sql.named('''
        insert into audit_log (user_id, device_id, action, entity_type,
                               entity_id, after)
        values (@u:uuid, @id:uuid, 'devices.register', 'devices', @eid:text,
                @after:jsonb)'''),
      parameters: {
        'u': userId,
        'id': deviceId,
        'eid': deviceId,
        'after': device,
      },
    );
    return (device: device, created: true);
  });

  Future<Map<String, Object?>?> _read(TxSession tx, String id) async {
    final rows = await tx.execute(
      Sql.named('''
        select id, name, platform, series_prefix, barcode_digit, active,
               version
        from devices where id = @id:uuid'''),
      parameters: {'id': id},
    );
    if (rows.isEmpty) return null;
    final series = await tx.execute(
      Sql.named('''
        select doc_type, next_number from document_series
        where device_id = @id:uuid order by doc_type'''),
      parameters: {'id': id},
    );
    final r = rows.single;
    return {
      'id': r[0],
      'name': r[1],
      'platform': r[2],
      'series_prefix': r[3],
      'barcode_digit': r[4],
      'active': r[5],
      'version': r[6],
      'series': [
        for (final s in series) {'doc_type': s[0], 'next_number': s[1]},
      ],
    };
  }
}
