defmodule Cashier.Repo.Migrations.CreateProducts do
  use Ecto.Migration

  def change do
    create table(:products) do
      add :sku, :string, null: false
      add :name, :string, null: false
      add :list_price, :integer, null: false
      add :currency, :string, null: false

      timestamps()
    end

    create unique_index(:products, [:sku])
  end
end
