defmodule App.Billing.UsageEvent do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "billing_usage_events" do
    field :quantity, :integer
    field :quantity_credited, :integer
    field :quantity_exceeded, :integer

    belongs_to :account, App.Billing.Account

    timestamps(updated_at: false)
  end

  @doc false
  def changeset(usage_event, quantity, quantity_credited, quantity_exceeded)
      when quantity > 0 and quantity_credited >= 0 and quantity_exceeded >= 0 do
    change(usage_event,
      quantity: quantity,
      quantity_credited: quantity_credited,
      quantity_exceeded: quantity_exceeded
    )
  end
end
