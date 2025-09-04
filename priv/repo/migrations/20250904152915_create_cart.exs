defmodule Cashier.Repo.Migrations.CreateCart do
  use Ecto.Migration

  def change do

    create table(:carts) do
      add :status, :string, null: false
      add :gross_total, :decimal, null: false
      add :discounts, :decimal, null: false
      add :net_total, :decimal, null: false

      timestamps()
    end

    # maybe an index for active cards
  end
end
