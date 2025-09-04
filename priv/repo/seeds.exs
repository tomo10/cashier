alias Cashier.{Repo, Product, Carts}

gr1 = Repo.insert!(%Product{sku: "GR1", name: "English Breakfast Tea", list_price: Decimal.new("3.11")})
cf1 = Repo.insert!(%Product{sku: "SR1", name: "Strawberries", list_price: Decimal.new("5.00")})
sr1 = Repo.insert!(%Product{sku: "CF1", name: "Coffee", list_price: Decimal.new("11.23")})

# Create a sample cart and add a couple of items
cart = Carts.create_cart(nil, %{status: :open})

# Add items
{:ok, _} = Carts.add_item_to_cart(cart.id, gr1.id, 2)
{:ok, _} = Carts.add_item_to_cart(cart.id, cf1.id, 1)
{:ok, _} = Carts.add_item_to_cart(cart.id, sr1.id, 3)
