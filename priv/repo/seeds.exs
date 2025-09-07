alias Cashier.{Repo, Product, Carts}

gr9 = Repo.insert!(%Product{sku: "GR9", name: "English Breakfast Tea", list_price: Decimal.new("3.11")})
cf9 = Repo.insert!(%Product{sku: "SR9", name: "Strawberries", list_price: Decimal.new("5.00")})
sr9 = Repo.insert!(%Product{sku: "CF9", name: "Coffee", list_price: Decimal.new("11.23")})

# Create a sample cart and add a couple of items
cart = Carts.create_cart(%{status: :open, gross_total: 0, discounts: 0, net_total: 0})

# Add items
{:ok, _} = Carts.add_item_to_cart(cart.id, gr9.id, 2)
{:ok, _} = Carts.add_item_to_cart(cart.id, cf9.id, 1)
{:ok, _} = Carts.add_item_to_cart(cart.id, sr9.id, 3)
