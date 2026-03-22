defmodule BanyWeb.MoneyHelper do
  def format_amount(_amount, nil), do: ""
  def format_amount(amount, currency) when is_binary(currency) do
    case Money.parse(Decimal.to_string(amount), String.to_atom(currency)) do
      {:ok, money} -> Money.to_string(money)
      _ -> Decimal.to_string(amount)
    end
  end
end
