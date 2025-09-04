defmodule Cashier.Specials do
  alias Cashier.CartItem

  # todo / nice to have -> want this to be some sort of external service where other ppl in company can adjust rules / promotions

  def bogo(%CartItem{} = item) do
    item
  end

  def calc_line_discounts() do
  end
end
