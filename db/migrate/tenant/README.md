# Tenant migrations

Per-tenant database: `db/tenants/<tenant_id>.sqlite3` — warehouse, product,
batch, stock, invoice, journal, production tables. **No table migrations exist
yet** (Phase 0.5).

Once tables are introduced (Phase 3+):

- File names: `001_create_warehouses.rb`, `002_create_products.rb`, …
- Every migration must be safe to run against an existing, populated tenant DB.
- Money `Decimal(15, 2)`, quantity `Decimal(15, 4)`, never `Float`.
- Index `product_batches.expired_at`; keep FEFO queries index-friendly.
- Apply to all tenants with `rake db:tenants:migrate`; new tenant with
  `rake 'db:tenants:create[slug]'`.
