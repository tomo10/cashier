defmodule Cashier.Specials do
  @zero Decimal.new("0")

  @rules [
    &__MODULE__.rule_gr1_bogo/1
  ]

  def calc_line_discounts(sku_item_map) do
    @rules
    |> Enum.map(& &1.(sku_item_map))
    |> Enum.map(&Decimal.round(&1, 2, :half_up))
    |> Enum.reduce(@zero, &Decimal.add/2)
  end

  def rule_gr1_bogo(%{"GR1" => %Cashier.CartItem{quantity: q, list_unit_price: p}}) when q >= 2 do
    free = div(q, 2)
    Decimal.mult(p, Decimal.new(free))
  end

  def rule_gr1_bogo(_), do: @zero
end
