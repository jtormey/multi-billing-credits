defmodule AppWeb.DemoLive do
  use AppWeb, :live_view

  alias App.Billing

  def mount(_params, _session, socket) do
    account = Billing.get_or_create_account()

    {:ok,
     socket
     |> assign(:account, account)
     |> assign(:account_usage, Billing.get_usage(account))
     |> stream(:credits, Billing.list_active_credits(account))
     |> assign(:credits_balance, Billing.sum_active_credits(account))}
  end

  def handle_event("add_credit", _params, socket) do
    credit = Billing.credit_account(socket.assigns.account, Enum.random(1..10))
    {:noreply, stream_insert(socket, :credits, credit)}
  end

  def handle_event("record_usage", %{"quantity" => quantity}, socket) do
    Billing.record_usage_event(
      socket.assigns.account,
      String.to_integer(quantity)
    )
    |> case do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "Recorded usage!")
         |> push_navigate(to: ~p"/")}

      {:error, :will_exceed_usage} ->
        {:noreply,
         socket
         |> put_flash(:error, "Sorry! That would exceed your usage limit.")
         |> push_navigate(to: ~p"/")}
    end
  end
end
