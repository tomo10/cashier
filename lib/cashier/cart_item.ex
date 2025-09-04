defmodule Cashier.CartItem do
  use Ecto.Schema
  import Ecto.Changeset

  schema "cart_items" do
    field(:sku, :string)
    field(:name, :string)

    field(:list_unit_price, :decimal)
    field(:quantity, :integer, default: 1)

    belongs_to(:cart, Cashier.Cart)
    belongs_to(:product, Cashier.Product)

    timestamps()
  end

  def changeset(cart_item, attrs) do
    cart_item
    |> cast(attrs, [:sku, :name, :list_unit_price, :quantity, :cart_id, :product_id])
    |> validate_required([:sku, :name, :list_unit_price, :quantity, :cart_id, :product_id])
    |> validate_number(:quantity, greater_than: 0)
    |> foreign_key_constraint(:cart_id)
    |> foreign_key_constraint(:product_id)
    |> unique_constraint([:cart_id, :product_id])
  end
end
