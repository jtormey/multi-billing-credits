defmodule App.Billing.AccountCredit do
  use Ecto.Schema
  import Ecto.Changeset

  schema "billing_account_credits" do
    field :quantity, :integer
    field :quantity_consumed, :integer, default: 0
    field :expires_at, :naive_datetime

    belongs_to :account, App.Billing.Account

    timestamps()
  end

  @doc false
  def credit_changeset(credit, quantity, expires_at \\ nil) when quantity > 0 do
    change(credit, quantity: quantity, expires_at: expires_at)
  end

  @doc false
  def consume_changeset(credit, consume_quantity) do
    if consume_quantity > remaining_quantity(credit),
      do: raise("Unable to consume more credits than are remaining")

    change(credit, quantity_consumed: credit.quantity_consumed + consume_quantity)
  end

  @doc false
  def expire_changeset(credit, datetime) do
    change(credit, expires_at: NaiveDateTime.truncate(datetime, :second))
  end

  def remaining_quantity(credit), do: credit.quantity - credit.quantity_consumed
end
