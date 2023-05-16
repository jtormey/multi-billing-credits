defmodule App.BillingTest do
  use App.DataCase

  alias App.Repo
  alias App.Billing

  setup do
    %{account: Billing.get_or_create_account(3)}
  end

  describe "record_usage_event_multi/4" do
    test "inserts a basic usage event", %{account: account} do
      assert {:ok, result} =
               account
               |> Billing.record_usage_event_multi(1)
               |> Repo.transaction()

      assert %{quantity: 1, quantity_credited: 0, quantity_exceeded: 0} = result.usage_event
    end

    test "inserts a basic usage event with exceeded usage", %{account: account} do
      assert {:ok, result} =
               account
               |> Billing.record_usage_event_multi(5)
               |> Repo.transaction()

      assert %{quantity: 5, quantity_credited: 0, quantity_exceeded: 2} = result.usage_event
    end

    test "ignores invalid credits", %{account: account} do
      Billing.credit_account(
        account,
        5,
        NaiveDateTime.truncate(NaiveDateTime.add(NaiveDateTime.utc_now(), -1, :minute), :second)
      )

      assert {:ok, result} =
               account
               |> Billing.record_usage_event_multi(4)
               |> Repo.transaction()

      assert %{quantity: 4, quantity_credited: 0, quantity_exceeded: 1} = result.usage_event
    end

    test "consumes a credit", %{account: account} do
      Billing.credit_account(account, 1)

      assert {:ok, result} =
               account
               |> Billing.record_usage_event_multi(4)
               |> Repo.transaction()

      assert %{quantity: 4, quantity_credited: 1, quantity_exceeded: 0} = result.usage_event

      assert %{quantity: 1, quantity_consumed: 1} = result.account_credit_0
    end

    test "does not consume a credit if below usage limit", %{account: account} do
      Billing.credit_account(account, 1)

      assert {:ok, result} =
               account
               |> Billing.record_usage_event_multi(3)
               |> Repo.transaction()

      assert %{quantity: 3, quantity_credited: 0, quantity_exceeded: 0} = result.usage_event
    end

    test "partially consumes a credit", %{account: account} do
      Billing.credit_account(account, 5)

      assert {:ok, result} =
               account
               |> Billing.record_usage_event_multi(6)
               |> Repo.transaction()

      assert %{quantity: 6, quantity_credited: 3, quantity_exceeded: 0} = result.usage_event

      assert %{quantity: 5, quantity_consumed: 3} = result.account_credit_0
    end

    test "consumes a credit with a balance remaining", %{account: account} do
      Billing.credit_account(account, 5)

      assert {:ok, result} =
               account
               |> Billing.record_usage_event_multi(15)
               |> Repo.transaction()

      assert %{quantity: 15, quantity_credited: 5, quantity_exceeded: 7} = result.usage_event

      assert %{quantity: 5, quantity_consumed: 5} = result.account_credit_0
    end

    test "partially consumes multiple credits", %{account: account} do
      Billing.credit_account(account, 1)
      Billing.credit_account(account, 2)
      Billing.credit_account(account, 3)

      assert {:ok, result} =
               account
               |> Billing.record_usage_event_multi(7)
               |> Repo.transaction()

      assert %{quantity: 7, quantity_credited: 4, quantity_exceeded: 0} = result.usage_event

      assert %{quantity: 1, quantity_consumed: 1} = result.account_credit_0
      assert %{quantity: 2, quantity_consumed: 2} = result.account_credit_1
      assert %{quantity: 3, quantity_consumed: 1} = result.account_credit_2
    end

    test "consumes multiple credits with a balance remaining", %{account: account} do
      Billing.credit_account(account, 3)
      Billing.credit_account(account, 6)
      Billing.credit_account(account, 9)

      assert {:ok, result} =
               account
               |> Billing.record_usage_event_multi(25)
               |> Repo.transaction()

      assert %{quantity: 25, quantity_credited: 18, quantity_exceeded: 4} = result.usage_event

      assert %{quantity: 3, quantity_consumed: 3} = result.account_credit_0
      assert %{quantity: 6, quantity_consumed: 6} = result.account_credit_1
      assert %{quantity: 9, quantity_consumed: 9} = result.account_credit_2
    end
  end
end
