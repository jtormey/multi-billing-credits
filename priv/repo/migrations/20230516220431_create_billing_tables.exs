defmodule App.Repo.Migrations.CreateBillingTables do
  use Ecto.Migration

  def change do
    create table(:billing_accounts, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :units_per_month_limit, :integer, null: false

      timestamps()
    end

    create table(:billing_account_credits, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :quantity, :integer
      add :quantity_consumed, :integer
      add :expires_at, :naive_datetime
      add :account_id, references(:billing_accounts, type: :binary_id), null: false

      timestamps()
    end

    create table(:billing_usage_events, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :quantity, :integer
      add :quantity_credited, :integer
      add :quantity_exceeded, :integer
      add :account_id, references(:billing_accounts, type: :binary_id), null: false

      timestamps(updated_at: false)
    end
  end
end
