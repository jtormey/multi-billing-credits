defmodule App.Repo.Migrations.CreateBillingTables do
  use Ecto.Migration

  def change do
    create table(:billing_accounts) do
      add :units_per_month_limit, :integer, null: false

      timestamps()
    end

    create table(:billing_account_credits) do
      add :quantity, :integer
      add :quantity_consumed, :integer
      add :expires_at, :naive_datetime
      add :account_id, references(:billing_accounts), null: false

      timestamps()
    end

    create table(:billing_usage_events) do
      add :quantity, :integer
      add :quantity_credited, :integer
      add :quantity_exceeded, :integer
      add :account_id, references(:billing_accounts), null: false

      timestamps(updated_at: false)
    end
  end
end
