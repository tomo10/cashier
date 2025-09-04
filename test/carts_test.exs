defmodule Cashier.CartsTest do
  use ExUnit.Case, async: true

  alias Cashier.{Carts, Repo, Cart}
  alias Cashier.Product

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
    :ok
  end

  test "create_cart/2 inserts a cart with defaults" do
    cart = Carts.create_cart(nil, %{status: :open})

    assert %Cart{id: id, status: :open} = cart
    assert is_integer(id)

    # Fetch from DB to ensure it persisted
    from_db = Repo.get!(Cart, id)
    assert from_db.status == :open
  end

  test "add_item_to_cart inserts when not present and increments when present" do
    cart = Carts.create_cart(nil, %{status: :open})

    {:ok, product} =
      %Product{}
      |> Product.changeset(%{
        sku: "SKU-1",
        name: "Widget",
        list_price: Decimal.new("9.99"),
        currency: "EUR"
      })
      |> Repo.insert()

    # Insert
    assert {:ok, item1} = Carts.add_item_to_cart(cart.id, product.id, 2)
    assert item1.quantity == 2

    # Increment
    assert {:ok, item2} = Carts.add_item_to_cart(cart.id, product.id, 3)
    assert item2.quantity == 5
  end
end
