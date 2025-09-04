defmodule Cashier.Cart do
  use Ecto.Schema
  import Ecto.Changeset

  @status ~w(open closed)a

  schema "carts" do
    field(:status, Ecto.Enum, values: @status)

    has_many(:cart_items, Cashier.CartItem)
    # belongs_to :user, Cashier.User

    timestamps()
  end

  @doc false
  def changeset(product, attrs) do
    product
    |> cast(attrs, [:status])
    |> validate_required([:status])
  end
end
