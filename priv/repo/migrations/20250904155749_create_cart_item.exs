defmodule Cashier.Repo.Migrations.CreateCartItem do
  use Ecto.Migration

  def change do
    create table(:cart_items) do
      add :cart_id, references(:carts, on_delete: :delete_all), null: false
      add :product_id, references(:products, on_delete: :restrict), null: false

      add :sku, :string, null: false
      add :name, :string, null: false
      add :list_unit_price, :decimal, null: false
      add :quantity, :integer, null: false, default: 1

      timestamps()
    end

    create index(:cart_items, [:cart_id])
    create unique_index(:cart_items, [:cart_id, :product_id],
      name: :cart_items_cart_id_product_id_index
    )
  end
end
