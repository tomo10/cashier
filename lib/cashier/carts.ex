defmodule Cashier.Carts do
  import Ecto.Query, warn: false
  alias Cashier.Repo

  alias Cashier.Cart
  alias Cashier.{CartItem, Product}
  alias Cashier.Specials

  def get_all_carts() do
    Repo.all(Cart)
  end

  def get_cart_by_id(id) do
    Repo.get(Cart, id)
  end

  def create_cart(user_id, attrs \\ %{}) do
    attrs = Map.put(attrs, :user_id, user_id)

    %Cart{}
    |> Cart.changeset(attrs)
    |> Repo.insert!()
  end

  @doc """
  Add a product to a cart.

  - If the product is not yet in the cart, inserts a new CartItem with the
    product's sku, name, and list price, setting the given quantity (default 1).
  - If it already exists, increment the quantitty.

  Returns {:ok, %CartItem{}} or {:error, reason}.
  """
  def add_item_to_cart(cart_id, product_id, quantity \\ 1)

  def add_item_to_cart(cart_id, product_id, quantity)
      when is_integer(quantity) and quantity > 0 do
    with %Cart{} = cart <- Repo.get(Cart, cart_id) || {:error, :cart_not_found},
         %Product{} = product <- Repo.get(Product, product_id) || {:error, :product_not_found} do
      case Repo.get_by(CartItem, cart_id: cart_id, product_id: product_id) do
        nil ->
          attrs = %{
            cart_id: cart_id,
            product_id: product_id,
            sku: product.sku,
            name: product.name,
            list_unit_price: product.list_price,
            quantity: quantity
          }

          case %CartItem{} |> CartItem.changeset(attrs) |> Repo.insert() do
            {:ok, item} ->
              update_cart_totals(cart, item)
              {:ok, item}

            error ->
              error
          end

        %CartItem{} = item ->
          new_quantity = item.quantity + quantity

          case item |> Ecto.Changeset.change(%{quantity: new_quantity}) |> Repo.update() do
            {:ok, item} ->
              update_cart_totals(cart, item)
              {:ok, item}

            error ->
              error
          end
      end
    end
  end

  def add_item_to_cart(_cart_id, _product_id, quantity) when is_integer(quantity) do
    {:error, :invalid_quantity}
  end

  def get_cart_items(cart_id) do
    Repo.all(from(ci in CartItem, where: ci.cart_id == ^cart_id))
  end

  def update_cart_totals(cart, item) do
    %{gross_total: gt, discounts: ds, net_total: _nt} =
      Map.take(cart, [:gross_total, :discounts, :net_total])

    line_total = Decimal.mult(item.list_unit_price, Decimal.new(item.quantity))
    new_gt = Decimal.add(gt, line_total)

    line_discounts = Decimal.new("0")
    new_ds = Decimal.add(ds, line_discounts)

    new_nt = Decimal.sub(new_gt, new_ds)

    totals = %{gross_total: new_gt, discounts: new_ds, net_total: new_nt}

    cart
    |> Ecto.Changeset.change(totals)
    |> Repo.update!()
  end
end
