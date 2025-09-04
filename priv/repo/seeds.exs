alias Cashier.{Repo, Product}

Repo.insert!(%Product{sku: "GR1", name: "English Breakfast Tea", list_price: Decimal.new("3.11")})
Repo.insert!(%Product{sku: "SR1", name: "Strawberries", list_price: Decimal.new("5.00")})
Repo.insert!(%Product{sku: "CF1", name: "Coffee", list_price: Decimal.new("11.23")})
