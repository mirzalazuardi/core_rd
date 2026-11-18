# frozen_string_literal: true

Sequel.migration do
  change do
    create_table(:accounts) do
      primary_key :id
      String :email, null: false, unique: true
      Integer :status_id, null: false, default: 2
    end

    create_table(:account_password_hashes) do
      foreign_key :id, :accounts, primary_key: true, on_delete: :cascade
      String :password_hash, null: false
    end

    create_table(:account_jwt_refresh_keys) do
      primary_key :id
      foreign_key :account_id, :accounts, null: false, on_delete: :cascade
      String :key, null: false
      DateTime :deadline, null: false

      index [:account_id, :key], unique: true
    end
  end
end
