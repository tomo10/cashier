defmodule Cashier.Product do
  use Ecto.Schema
  import Ecto.Changeset

  schema "products" do
    field(:sku, :string)
    field(:name, :string)
    field(:list_price, :decimal)
    field(:currency, :string, default: "GBP")

    timestamps()
  end

  @doc false
  def changeset(product, attrs) do
    product
    |> cast(attrs, [:sku, :name, :list_price, :currency])
    |> validate_required([:sku, :name, :list_price, :currency])
    |> unique_constraint(:sku)
  end
end
