defmodule App.Billing.Account do
  use Ecto.Schema

  @primary_key {:id, :binary_id, autogenerate: true}

  schema "billing_accounts" do
    field :units_per_month_limit, :integer, default: 0

    has_many :usage_events, App.Billing.UsageEvent
    has_many :credits, App.Billing.AccountCredit, preload_order: [desc: :inserted_at]

    timestamps()
  end
end
