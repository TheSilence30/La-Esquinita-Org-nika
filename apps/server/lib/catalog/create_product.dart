import 'package:esquinita_core/esquinita_core.dart';
import 'package:postgres/postgres.dart';

/// Applies `CreateProduct` (docs/modelo-datos.md §6) inside the push
/// transaction: product, first cost, presentations, barcodes, lots and the
/// initial stock as `initial` movements (the stock_movements trigger keeps
/// the balances and on_hand). Checks that need the database come first, so
/// a refusal leaves nothing behind.
///
/// A barcode another product already has is left out and recorded as a
/// `duplicate_barcode` conflict for the Administrador to merge; the product
/// is created anyway, so nothing done offline is lost (CLAUDE.md §7).
Future<(PushStatus, String?)> applyCreateProduct(
  TxSession tx,
  SyncCommand c,
  CreateProduct p,
) async {
  final refs = (await tx.execute(
    Sql.named('''
      select exists (select 1 from categories where id = @cat:uuid),
             exists (select 1 from units where id = @unit:uuid),
             @brand:uuid is null
               or exists (select 1 from brands where id = @brand:uuid),
             exists (select 1 from products
                     where id = @id:uuid or internal_code = @code:text),
             exists (
               select 1 from users u
               join user_roles ur on ur.user_id = u.id and ur.active
               join roles r on r.id = ur.role_id and r.active
               join role_permissions rp on rp.role_id = r.id and rp.active
               join permissions pe on pe.code = rp.permission_code
                 and pe.active
               where u.id = @user:uuid and u.active
                 and pe.code = 'catalog.create')'''),
    parameters: {
      'cat': p.categoryId,
      'unit': p.baseUnitId,
      'brand': p.brandId,
      'id': p.productId,
      'code': p.internalCode,
      'user': c.userId,
    },
  )).single;
  final refused = switch (refs) {
    [false, _, _, _, _] => 'Categoría desconocida.',
    [_, false, _, _, _] => 'Unidad desconocida.',
    [_, _, false, _, _] => 'Marca desconocida.',
    [_, _, _, true, _] => 'El producto o su código interno ya existe.',
    [_, _, _, _, false] => 'El usuario no puede registrar productos.',
    _ => null,
  };
  if (refused != null) return (PushStatus.rejected, refused);

  await tx.execute(
    Sql.named('''
      insert into products (id, internal_code, name, description, category_id,
        brand_id, base_unit_id, tracks_lots, min_stock_milli, version)
      values (@id:uuid, @code:text, @name:text, @desc:text, @cat:uuid,
              @brand:uuid, @unit:uuid, @lots:boolean, @min:int8, 0)'''),
    parameters: {
      'id': p.productId,
      'code': p.internalCode,
      'name': p.name.trim(),
      'desc': p.description,
      'cat': p.categoryId,
      'brand': p.brandId,
      'unit': p.baseUnitId,
      'lots': p.tracksLots,
      'min': p.minStockMilli,
    },
  );
  await tx.execute(
    Sql.named('''
      insert into product_costs (product_id, avg_cost_cents, last_cost_cents,
                                 version)
      values (@id:uuid, @cost:int8, @cost:int8, 0)'''),
    parameters: {'id': p.productId, 'cost': p.unitCostCents},
  );

  final duplicates = <String>[];
  for (final x in p.presentations) {
    await tx.execute(
      Sql.named('''
        insert into product_presentations (id, product_id, name, factor_milli,
          is_base, retail_price_cents, wholesale_price_cents,
          wholesale_min_milli, version)
        values (@id:uuid, @p:uuid, @name:text, @f:int8, @base:boolean,
                @retail:int8, @whole:int8, @min:int8, 0)'''),
      parameters: {
        'id': x.id,
        'p': p.productId,
        'name': x.name.trim(),
        'f': x.factorMilli,
        'base': x.isBase,
        'retail': x.retailPriceCents,
        'whole': x.wholesalePriceCents,
        'min': x.wholesaleMinMilli,
      },
    );
    for (final b in x.barcodes) {
      final code = b.code.trim();
      final inserted = await tx.execute(
        Sql.named('''
          insert into barcodes (code, presentation_id, format, generated,
                                version)
          values (@code:text, @pres:uuid, @f:text, @g:boolean, 0)
          on conflict (code) do nothing
          returning code'''),
        parameters: {
          'code': code,
          'pres': x.id,
          'f': b.format.name,
          'g': b.generated,
        },
      );
      if (inserted.isNotEmpty) continue;
      duplicates.add(code);
      await tx.execute(
        Sql.named('''
          insert into sync_conflicts (type, op_id, entity_type, entity_id,
                                      details)
          select 'duplicate_barcode', @op:uuid, 'barcodes', @code:text,
                 jsonb_build_object('code', @code:text,
                   'new_product_id', @p:text,
                   'new_presentation_id', @pres:text,
                   'existing_presentation_id', presentation_id)
          from barcodes where code = @code:text'''),
        parameters: {
          'op': c.opId,
          'code': code,
          'p': p.productId,
          'pres': x.id,
        },
      );
    }
  }

  final lots = <String>{};
  for (final s in p.initialStock) {
    if (s.lotId case final lot? when lots.add(lot)) {
      await tx.execute(
        Sql.named('''
          insert into lots (id, product_id, lot_code, expires_on, version)
          values (@id:uuid, @p:uuid, @code:text, @exp:date, 0)'''),
        parameters: {
          'id': lot,
          'p': p.productId,
          'code': s.lotCode!.trim(),
          'exp': s.expiresOn == null ? null : DateTime.parse(s.expiresOn!),
        },
      );
    }
    await tx.execute(
      Sql.named('''
        insert into stock_movements (id, product_id, lot_id, qty_milli, type,
          unit_cost_cents, source_type, source_id, op_id, device_id, user_id,
          occurred_at)
        values (@id:uuid, @p:uuid, @lot:uuid, @q:int8, 'initial', @cost:int8,
                'product', @p:uuid, @op:uuid, @d:uuid, @u:uuid,
                @at:timestamptz)'''),
      parameters: {
        'id': s.movementId,
        'p': p.productId,
        'lot': s.lotId,
        'q': s.qtyMilli,
        'cost': p.unitCostCents,
        'op': c.opId,
        'd': c.deviceId,
        'u': c.userId,
        'at': c.createdAt,
      },
    );
  }

  await tx.execute(
    Sql.named('''
      insert into audit_log (user_id, device_id, action, entity_type,
                             entity_id, after, op_id)
      values (@u:uuid, @d:uuid, 'catalog.create', 'products', @p:text,
              @after:jsonb, @op:uuid)'''),
    parameters: {
      'u': c.userId,
      'd': c.deviceId,
      'p': p.productId,
      'after': {
        'name': p.name.trim(),
        'internal_code': p.internalCode,
        'initial_stock_milli': p.initialStock.fold<int>(
          0,
          (a, s) => a + s.qtyMilli,
        ),
        if (duplicates.isNotEmpty) 'duplicate_barcodes': duplicates,
      },
      'op': c.opId,
    },
  );
  return duplicates.isEmpty
      ? (PushStatus.applied, null)
      : (
          PushStatus.conflict,
          'Producto registrado, pero el código ${duplicates.join(', ')} ya es '
              'de otro producto: el Administrador debe unirlos.',
        );
}
