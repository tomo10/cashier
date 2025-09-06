defmodule Cashier.Carts do
  import Ecto.Query, warn: false
  alias Cashier.Repo

  alias Cashier.{CartItem, Product, Cart, Specials}

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

  defp validate_quantity(q) when is_integer(q) and q > 0, do: :ok
  defp validate_quantity(_), do: {:error, :invalid_quantity}

  def add_item_to_cart(cart_id, product_id, quantity \\ 1)

  def add_item_to_cart(cart_id, product_id, quantity) do
    with :ok <- validate_quantity(quantity),
         %Cart{} = cart <- Repo.get(Cart, cart_id) || {:error, :cart_not_found},
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

          with {:ok, item} <- %CartItem{} |> CartItem.changeset(attrs) |> Repo.insert() do
            recompute_totals!(cart)
            {:ok, item}
          end

        %CartItem{} = item ->
          new_quantity = item.quantity + quantity

          with {:ok, item} <-
                 item
                 |> Ecto.Changeset.change(%{quantity: new_quantity})
                 |> Repo.update() do
            recompute_totals!(cart)
            {:ok, item}
          end
      end
    end
  end

  def remove_item_from_cart(cart_id, product_id, quantity) do
    with :ok <- validate_quantity(quantity),
         %Cart{} = cart <- Repo.get(Cart, cart_id) || {:error, :cart_not_found} do
      case Repo.get_by(CartItem, cart_id: cart_id, product_id: product_id) do
        %CartItem{} = item ->
          new_quantity = item.quantity - quantity

          cond do
            new_quantity < 0 ->
              {:error, :insufficient_quantity}

            new_quantity == 0 ->
              {:ok, _} = Repo.delete(item)
              recompute_totals!(cart)
              {:ok, :removed}

            true ->
              with {:ok, item} <-
                     item
                     |> Ecto.Changeset.change(%{quantity: new_quantity})
                     |> Repo.update() do
                recompute_totals!(cart)
                {:ok, item}
              end
          end

        nil ->
          {:error, :item_not_found}
      end
    end
  end

  @zero Decimal.new("0")

  def recompute_totals!(%Cart{id: cart_id} = cart) do
    items = Repo.all(from(ci in CartItem, where: ci.cart_id == ^cart_id))

    gross_total =
      Enum.reduce(items, @zero, fn item, acc ->
        Decimal.add(acc, Decimal.mult(item.list_unit_price, Decimal.new(item.quantity)))
      end)

    discounts =
      case Specials.calc_line_discounts(items) do
        %Decimal{} = d -> d
        _ -> @zero
      end

    net_total = Decimal.sub(gross_total, discounts)

    totals = %{gross_total: gross_total, discounts: discounts, net_total: net_total}

    cart
    |> Ecto.Changeset.change(totals)
    |> Repo.update!()
  end
end
