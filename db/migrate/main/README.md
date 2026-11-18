# Main migrations

Global database: `db/main.sqlite3` — Rodauth accounts today; `tenants` and
`memberships` arrive in Phase 2.

- File names: `001_create_rodauth.rb`, `002_…`
- Plain Sequel migrations (`Sequel.migration { change { ... } }`), no ActiveSupport.
- Money `Decimal(15, 2)`, quantity `Decimal(15, 4)`, never `Float`.
- Run with `rake db:migrate`.
- Foreign keys are enforced (`PRAGMA foreign_keys = ON`), so define them explicitly.

`001_create_rodauth.rb` creates `accounts`, `account_password_hashes`, and
`account_jwt_refresh_keys` (JWT refresh tokens used by the API configuration).
