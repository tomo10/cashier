defmodule Cashier.CartItems do
  @moduledoc """
  Domain operations for cart items.
  """
  import Ecto.Query, warn: false
  alias Cashier.Repo

  alias Cashier.CartItem

  def get_items_by_cart(cart_id) do
    Repo.all(from(ci in CartItem, where: ci.cart_id == ^cart_id))
  end

  def get_item_by_cart_product_ids(cart_id, product_id) do
    case Repo.get_by(CartItem, cart_id: cart_id, product_id: product_id) do
      %CartItem{} = ci -> ci
      nil -> {:error, :item_not_found}
    end
  end
end
