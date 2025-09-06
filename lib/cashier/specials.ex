defmodule Cashier.Specials do
  alias Cashier.CartItem

  # todo / nice to have -> want this to be some sort of external service where other ppl in company can adjust rules / promotions

  def bogo(%CartItem{} = item) do
    item
  end

  def calc_line_discounts(all_items) do
    items_by_sku =
      Enum.reduce(all_items, %{}, fn {_sku, [cart_item]}, acc ->
        Map.update(
          acc,
          cart_item.sku,
          %{qty: cart_item.quantity, price: cart_item.list_unit_price},
          fn m -> %{qty: m.qty + cart_item.quantity, price: m.price} end
        )
      end)

    with %{qty: q, price: p} <- Map.get(items_by_sku, "GR1") do
      free = div(q, 2)
      Decimal.mult(p, Decimal.new(free))
    else
      _ -> Decimal.new("0")
    end
  end
end
