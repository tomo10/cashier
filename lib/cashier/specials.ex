defmodule Cashier.Specials do
  @zero Decimal.new("0")

  def calc_line_discounts(all_items) do
    # turn items list into a map for easy lookup
    items_by_sku = Map.new(all_items, &{&1.sku, &1})

    gr1 =
      with %{quantity: q, list_unit_price: p} <- Map.get(items_by_sku, "GR1") do
        free = div(q, 2)
        Decimal.mult(p, Decimal.new(free))
      else
        _ -> @zero
      end

    sr1 =
      with %{quantity: q} when q > 2 <- Map.get(items_by_sku, "SR1") do
        Decimal.mult(q, Decimal.new("0.5"))
      else
        _ -> @zero
      end

    cf1 =
      with %{quantity: q, list_unit_price: p} when q > 2 <- Map.get(items_by_sku, "CF1") do
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

  defp calc_product_line_discount() do
  end
end
