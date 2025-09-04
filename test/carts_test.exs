defmodule Cashier.CartsTest do
  use ExUnit.Case, async: true

  alias Cashier.{Carts, Repo, Cart}

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
end
