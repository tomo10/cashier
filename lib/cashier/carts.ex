defmodule Cashier.Carts do
  import Ecto.Query, warn: false
  alias Cashier.Repo

  alias Cashier.{CartItem, Product, Cart, Specials}
  alias Cashier.Products
  alias Cashier.CartItems, as: CI

  def get_all_carts() do
    Repo.all(Cart)
  end

  def get_cart_by_id(id) do
    case Repo.get(Cart, id) do
      %Cart{} = cart -> cart
      nil -> {:error, :cart_not_found}
    end
  end

  def create_cart(attrs \\ %{}) do
    %Cart{}
    |> Cart.changeset(attrs)
    |> Repo.insert!()
  end

  defp validate_quantity(q) when is_integer(q) and q > 0, do: :ok
  defp validate_quantity(_), do: {:error, :invalid_quantity}

  def add_item_to_cart(cart_id, product_id, quantity \\ 1)

  def add_item_to_cart(cart_id, product_id, quantity) do
    Repo.transaction(fn ->
      with :ok <- validate_quantity(quantity),
           %Cart{} = cart <- get_cart_by_id(cart_id),
           %Product{} = product <- Products.get_product_by_id(product_id) do
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
              item
            end

          %CartItem{} = item ->
            new_quantity = item.quantity + quantity

            with {:ok, item} <-
                   item
                   |> Ecto.Changeset.change(%{quantity: new_quantity})
                   |> Repo.update() do
              recompute_totals!(cart)
              item
            end
        end
      else
        {:error, reason} -> Repo.rollback(reason)
      end
    end)
  end

  def remove_item_from_cart(cart_id, product_id, quantity) do
    Repo.transaction(fn ->
      with :ok <- validate_quantity(quantity),
           %Cart{} = cart <- get_cart_by_id(cart_id),
           %CartItem{} = item <- CI.get_item_by_cart_product_ids(cart_id, product_id) do
        new_quantity = item.quantity - quantity

        cond do
          new_quantity < 0 ->
            Repo.rollback(:insufficient_quantity)

          new_quantity == 0 ->
            {:ok, _} = Repo.delete(item)
            recompute_totals!(cart)
            :removed

          true ->
            {:ok, item} =
              item
              |> Ecto.Changeset.change(%{quantity: new_quantity})
              |> Repo.update()

            recompute_totals!(cart)
            item
        end
      else
        {:error, reason} -> Repo.rollback(reason)
      end
    end)
  end

  @zero Decimal.new("0")

  def recompute_totals!(%Cart{id: cart_id} = cart) do
    items = CI.get_items_by_cart(cart_id)

    gross_total =
      Enum.reduce(items, @zero, fn item, acc ->
        Decimal.add(acc, Decimal.mult(item.list_unit_price, Decimal.new(item.quantity)))
      end)

    discounts =
      case Map.new(items, &{&1.sku, &1}) |> Specials.calc_line_discounts() do
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
