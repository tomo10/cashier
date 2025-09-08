defmodule Cashier.Products do
  @moduledoc """
  Domain operations for products.
  """
  import Ecto.Query, warn: false
  alias Cashier.Repo

  alias Cashier.Product

  def get_product_by_id(id) do
    case Repo.get(Product, id) do
      %Product{} = product -> product
      nil -> {:error, :product_not_found}
    end
  end
end
