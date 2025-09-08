defmodule Cashier.Specials do
  @moduledoc """
  Pricing rules engine for cart discounts.

  Exposed API:
    calc_line_discounts/1 -> total Decimal discount given a map %{sku => %CartItem{}}

  Current rules:
    GR1: Buy-one-get-one-free (every 2nd free)
    SR1: 3+ strawberries -> price drops to £4.50 each
    CF1: 3+ coffees -> each at 2/3 original price

  Add new rules by appending a function to @rules that returns a Decimal discount.
  """

  alias Cashier.CartItem
  @zero Decimal.new("0")

  @rules [
    &__MODULE__.rule_gr1_bogo/1,
    &__MODULE__.rule_cf1_three_for_two_thirds/1,
    &__MODULE__.rule_sr1_bulk/1
  ]

  def calc_line_discounts(sku_item_map) do
    @rules
    |> Enum.map(& &1.(sku_item_map))
    |> Enum.map(&Decimal.round(&1, 2, :half_up))
    |> Enum.reduce(@zero, &Decimal.add/2)
  end

  def rule_gr1_bogo(%{"GR1" => %CartItem{quantity: q, list_unit_price: p}}) when q >= 2 do
    Decimal.mult(p, Decimal.new(div(q, 2)))
  end

  def rule_gr1_bogo(_), do: @zero

  def rule_sr1_bulk(%{"SR1" => %CartItem{quantity: q, list_unit_price: p}}) when q >= 3 do
    drop_to = Decimal.new("4.50")
    per_unit_disc = Decimal.sub(p, drop_to)

    Decimal.mult(per_unit_disc, Decimal.new(q))
  end

  def rule_sr1_bulk(_), do: @zero

  def rule_cf1_three_for_two_thirds(%{"CF1" => %CartItem{quantity: q, list_unit_price: p}})
      when q >= 3 do
    two_thirds = Decimal.div(Decimal.new(2), Decimal.new(3))
    new_unit_price = Decimal.mult(p, two_thirds)
    per_unit_disc = Decimal.sub(p, new_unit_price)

    Decimal.mult(per_unit_disc, Decimal.new(q))
  end

  def rule_cf1_three_for_two_thirds(_), do: @zero
end
