defmodule App.Billing do
  import Ecto.Query

  alias App.Repo

  alias App.Billing.Account
  alias App.Billing.AccountCredit
  alias App.Billing.UsageEvent

  ## Record Usage

  def record_usage_event(account, quantity) do
    multi = record_usage_event_multi(account, quantity)

    if will_exceed_usage_limit?(multi) do
      {:error, :will_exceed_usage}
    else
      Repo.transaction(multi)
    end
  end

  def will_exceed_usage_limit?(multi) do
    {:insert, usage_event, _} = Keyword.fetch!(Ecto.Multi.to_list(multi), :usage_event)

    Ecto.Changeset.fetch_change!(usage_event, :quantity_exceeded) > 0
  end

  def record_usage_event_multi(account, quantity) do
    usage = get_usage(account)
    credits = list_active_credits(account)

    quantity_exceeded = max(0, usage + quantity - account.units_per_month_limit)

    {multi, quantity_not_credited} = consume_credits_for_quantity(credits, quantity_exceeded)

    changeset =
      UsageEvent.changeset(
        %UsageEvent{account: account},
        quantity,
        quantity_exceeded - quantity_not_credited,
        quantity_not_credited
      )

    Ecto.Multi.insert(multi, :usage_event, changeset)
  end

  def consume_credits_for_quantity(credits, quantity) do
    credits
    |> Enum.with_index()
    |> Enum.reduce_while({Ecto.Multi.new(), quantity}, fn
      {_credit, _id}, {multi, 0} ->
        {:halt, {multi, 0}}

      {credit, i}, {multi, quantity} ->
        consume_quantity = min(quantity, AccountCredit.remaining_quantity(credit))

        multi =
          Ecto.Multi.update(
            multi,
            :"account_credit_#{i}",
            AccountCredit.consume_changeset(credit, consume_quantity)
          )

        {:cont, {multi, quantity - consume_quantity}}
    end)
  end

  ## Usage

  def get_usage(account) do
    Repo.one(
      from a in Account,
        left_join: u in assoc(a, :usage_events),
        where: a.id == ^account.id,
        select: coalesce(sum(u.quantity - u.quantity_credited - u.quantity_exceeded), 0)
    )
  end

  ## Credits Management

  def sum_active_credits(account) do
    active_credits_query(account)
    |> select([d], coalesce(sum(d.quantity - d.quantity_consumed), 0))
    |> Repo.one()
  end

  def list_active_credits(account) do
    active_credits_query(account)
    |> order_by(asc: :inserted_at)
    |> Repo.all()
  end

  def active_credits_query(account) do
    now = NaiveDateTime.utc_now()

    from(AccountCredit)
    |> where([d], d.account_id == ^account.id)
    |> where([d], is_nil(d.expires_at) or d.expires_at > ^now)
    |> where([d], d.quantity_consumed < d.quantity)
  end

  def credit_account(account, quantity, expires_at \\ nil) do
    %AccountCredit{account: account}
    |> AccountCredit.credit_changeset(quantity, expires_at)
    |> Repo.insert!()
  end

  ## Account

  def get_or_create_account(limit \\ 10) do
    with nil <- Repo.one(Account) do
      %Account{}
      |> Ecto.Changeset.change(units_per_month_limit: limit)
      |> Repo.insert!()
    end
  end
end
