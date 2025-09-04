defmodule Cashier.Carts do
  import Ecto.Query, warn: false
  alias Cashier.Repo

  alias Cashier.Cart

  def get_all_carts() do
    Repo.all(Cart)
  end

  def create_cart(user_id, attrs \\ %{}) do
    attrs = Map.put(attrs, :user_id, user_id)

    %Cart{}
    |> Cart.changeset(attrs)
    |> Repo.insert!()
  end
end
