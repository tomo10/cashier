defmodule Cashier.Cart do
  use Ecto.Schema
  import Ecto.Changeset

  @status ~w(open closed)a

  schema "carts" do
    field(:status, Ecto.Enum, values: @status)
    field(:gross_total, :decimal, default: Decimal.new("0"))
    field(:discounts, :decimal, default: Decimal.new("0"))
    field(:net_total, :decimal, default: Decimal.new("0"))

    has_many(:cart_items, Cashier.CartItem)

    timestamps()
  end

  @doc false
  def changeset(product, attrs) do
    product
    |> cast(attrs, [:status, :gross_total, :discounts, :net_total])
    |> validate_required([:status, :gross_total, :discounts, :net_total])
  end
end
