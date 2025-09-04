defmodule Cashier.Repo.Migrations.CreateCart do
  use Ecto.Migration

  def change do

    create table(:carts) do
      add :status, :string, null: false

      timestamps()
    end

    # maybe an index for active cards
  end
end
