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

  test "cart with multiple discounts with multiple items" do
    cart = init_cart()

    for attrs <- [
          @green_tea,
          @coffee,
          @strawberry,
          @coffee,
          @strawberry,
          @coffee,
          @strawberry,
          @coffee,
          @green_tea,
          @green_tea
        ] do
      product = product_fixture(attrs)
      assert {:ok, _item} = Carts.add_item_to_cart(cart.id, product.id, 1)
    end

    cart = Repo.get!(Cart, cart.id)
    assert cart.gross_total == Decimal.new("69.25")
    assert cart.net_total == Decimal.new("49.67")
  end

  test "remove_item_from_cart adjusts quantities and totals with correct discounts" do
    cart = init_cart()

    coffee = product_fixture(@coffee)
    tea = product_fixture(@green_tea)

    # Initial basket: 3 coffees + 2 teas
    assert {:ok, _} = Carts.add_item_to_cart(cart.id, coffee.id, 3)
    assert {:ok, _} = Carts.add_item_to_cart(cart.id, tea.id, 2)

    cart = Repo.get!(Cart, cart.id)
    assert cart.gross_total == Decimal.new("39.91")
    assert cart.net_total == Decimal.new("25.57")

    # Remove 1 coffee: quantity 2 -> coffee discount lost, net stays the same
    assert {:ok, _} = Carts.remove_item_from_cart(cart.id, coffee.id, 1)
    cart = Repo.get!(Cart, cart.id)
    assert cart.gross_total == Decimal.new("28.68")
    assert cart.net_total == Decimal.new("25.57")

    # Remove 1 tea. Cart is 1 tea and 2 coffees. Net and gross should be the same.
    assert {:ok, _} = Carts.remove_item_from_cart(cart.id, tea.id, 1)
    cart = Repo.get!(Cart, cart.id)
    assert cart.gross_total == Decimal.new("25.57")
    assert cart.net_total == Decimal.new("25.57")

    # Remove the remaining coffees (deletes coffee line)
    assert {:ok, :removed} = Carts.remove_item_from_cart(cart.id, coffee.id, 2)
    cart = Repo.get!(Cart, cart.id)

    # Only 1 tea remains. No discounts.
    assert cart.gross_total == Decimal.new("3.11")
    assert cart.net_total == Decimal.new("3.11")
  end

  test "add discounts, drop below discounts threshhold, then re-add to ensure no asymmetry" do
    cart = init_cart()
    coffee = product_fixture(@coffee)

    # Add 3 coffees -> discount applies
    assert {:ok, _} = Carts.add_item_to_cart(cart.id, coffee.id, 3)
    cart = Repo.get!(Cart, cart.id)
    assert cart.gross_total == Decimal.new("33.69")
    assert cart.net_total == Decimal.new("22.46")

    # Remove 1 coffee -> discount removed (2 coffees * 11.23)
    assert {:ok, _} = Carts.remove_item_from_cart(cart.id, coffee.id, 1)
    cart = Repo.get!(Cart, cart.id)
    assert cart.gross_total == Decimal.new("22.46")
    assert cart.net_total == Decimal.new("22.46")

    # Add 1 coffee -> back to 3, discount should re-apply
    assert {:ok, _} = Carts.add_item_to_cart(cart.id, coffee.id, 1)
    cart = Repo.get!(Cart, cart.id)
    assert cart.gross_total == Decimal.new("33.69")
    assert cart.net_total == Decimal.new("22.46")
  end

  test "remove larger quantity than exists in the cart returns error and leaves totals unchanged" do
    cart = init_cart()
    coffee = product_fixture(@coffee)
    assert {:ok, _} = Carts.add_item_to_cart(cart.id, coffee.id, 2)

    cart_before = Repo.get!(Cart, cart.id)
    assert cart_before.gross_total == Decimal.new("22.46")
    assert cart_before.net_total == Decimal.new("22.46")

    assert {:error, :insufficient_quantity} = Carts.remove_item_from_cart(cart.id, coffee.id, 3)

    # Totals unchanged after unsuccessful removal
    cart_after = Repo.get!(Cart, cart.id)
    assert cart_after.gross_total == Decimal.new("22.46")
    assert cart_after.net_total == Decimal.new("22.46")
  end
end
