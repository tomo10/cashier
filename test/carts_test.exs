defmodule Cashier.CartsTest do
  use ExUnit.Case, async: false

  alias Cashier.{Carts, Repo, Cart}
  alias Cashier.Product

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
    :ok
  end

  @strawberry %{name: "Strawberry", sku: "SR1", list_price: Decimal.new("5.00")}
  @green_tea %{name: "Green Tea", sku: "GR1", list_price: Decimal.new("3.11")}
  @coffee %{name: "Coffee", sku: "CF1", list_price: Decimal.new("11.23")}

  defp init_cart() do
    Carts.create_cart(nil, %{status: :open, gross_total: 0, discounts: 0, net_total: 0})
  end

  # defp unique_sku(prefix \\ "SKU"), do: "#{prefix}-#{System.unique_integer([:positive])}"

  defp product_fixture(attrs) do
    case Repo.get_by(Product, sku: attrs[:sku]) do
      nil ->
        %Product{} |> Product.changeset(attrs) |> Repo.insert!()

      product ->
        product
    end
  end

  test "create_cart/2 inserts a cart with defaults" do
    cart = init_cart()

    assert %Cart{id: id, status: :open} = cart
    assert is_integer(id)

    from_db = Repo.get!(Cart, id)
    assert from_db.status == :open
  end

  test "add_item_to_cart inserts when not present and increments when present" do
    cart = init_cart()
    product = product_fixture(@green_tea)

    assert {:ok, item1} = Carts.add_item_to_cart(cart.id, product.id, 2)
    assert item1.quantity == 2

    assert {:ok, item2} = Carts.add_item_to_cart(cart.id, product.id, 3)
    assert item2.quantity == 5
  end

  test "cart with bogof returns correct total" do
    cart = init_cart()

    product = product_fixture(@green_tea)
    assert {:ok, _item} = Carts.add_item_to_cart(cart.id, product.id, 2)

    cart = Repo.get!(Cart, cart.id)
    assert cart.net_total == Decimal.new("3.11")
  end

  test "cart with no discounts returns correct totals" do
    cart = init_cart()

    for attrs <- [@strawberry, @green_tea, @coffee] do
      product = product_fixture(attrs)
      assert {:ok, _item} = Carts.add_item_to_cart(cart.id, product.id, 1)
    end

    cart = Repo.get!(Cart, cart.id)
    assert cart.net_total == Decimal.new("19.34")
  end

  test "cart with bogof returns correct total with other items" do
    cart = init_cart()

    for attrs <- [@strawberry, @green_tea, @coffee, @green_tea] do
      product = product_fixture(attrs)
      assert {:ok, _item} = Carts.add_item_to_cart(cart.id, product.id, 1)
    end

    cart = Repo.get!(Cart, cart.id)
    assert cart.net_total == Decimal.new("19.34")
  end

  test "carts with 3 or more strawberries drops unit price to £4.50" do
    cart = init_cart()

    for attrs <- [@strawberry, @strawberry, @strawberry] do
      product = product_fixture(attrs)
      assert {:ok, _item} = Carts.add_item_to_cart(cart.id, product.id, 1)
    end

    cart = Repo.get!(Cart, cart.id)
    assert cart.gross_total == Decimal.new("15.00")
    assert cart.net_total == Decimal.new("13.50")
  end

  test "cart with 3 or more coffees the unit price drops by 33%" do
    cart = init_cart()

    for attrs <- [@coffee, @coffee, @coffee, @coffee] do
      product = product_fixture(attrs)
      assert {:ok, _item} = Carts.add_item_to_cart(cart.id, product.id, 1)
    end

    cart = Repo.get!(Cart, cart.id)
    assert cart.gross_total == Decimal.new("44.92")
    assert cart.net_total == Decimal.new("29.95")
  end
end
