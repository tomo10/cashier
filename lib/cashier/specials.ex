defmodule Cashier.Specials do
  # todo / nice to have -> want this to be some sort of external service where other ppl in company can adjust rules / promotions
  @zero Decimal.new("0")

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

    gr1 =
      with %{qty: q, price: p} <- Map.get(items_by_sku, "GR1") do
        free = div(q, 2)
        Decimal.mult(p, Decimal.new(free))
      else
        _ -> @zero
      end

    sr1 =
      with %{qty: q} when q > 2 <- Map.get(items_by_sku, "SR1") do
        Decimal.mult(q, Decimal.new("0.5"))
      else
        _ -> @zero
      end

    cf1 =
      with %{qty: q, price: p} when q > 2 <- Map.get(items_by_sku, "CF1") do
        total = Decimal.mult(Decimal.new(q), p)
        Decimal.div(total, Decimal.new(3))
      else
        _ -> @zero
      end

    # we round per line. apparently this is retail best practice
    Enum.reduce([gr1, sr1, cf1], @zero, fn disc, acc ->
      Decimal.round(disc, 2, :half_up) |> Decimal.add(acc)
    end)
  end
end
