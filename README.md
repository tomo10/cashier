# Cashier

An example Elixir/Ecto domain for a point‑of‑sale style shopping cart that applies promotional pricing rules (BOGOF, bulk quantity discounts) while maintaining accurate monetary totals in the database.

## What It Does

The core responsibilities:

- Create carts and add / remove products with quantity adjustments inside DB transactions.
- Maintain `gross_total`, `discounts`, and `net_total` columns on the `carts` table, recalculated on every mutation.
- Apply current promotional rules:
  - GR1 – Buy‑one‑get‑one‑free on Green Tea.
  - SR1 – Strawberries drop from £5.00 to £4.50 each once 3 or more are in the cart.
  - CF1 – when 3 or more coffees, total coffee discount equals 33% of all coffee units.
- Enforce validation & domain errors (e.g. `:invalid_quantity`, `:cart_not_found`, `:item_not_found`, `:insufficient_quantity`).

## Tech Stack

- Elixir 1.17+
- Ecto + PostgreSQL (`ecto_sql`, `postgrex`)
- Decimal arithmetic (using Decimal module) for money values.

## Quick Start

Ensure you have PostgreSQL running locally with credentials matching `config/config.exs` (default user/password `postgres` / `postgres`).

```bash
mix deps.get
mix compile

mix ecto.create
mix ecto.migrate
mix run priv/repo/seeds.exs

or if you prefer a single command:
mix ecto.reset
```

To open an IEx session with the application started:

```bash
iex -S mix
```

## Example Usage (IEx)

```elixir
# List existing carts and take first seeded cart
cart = Carts.get_all_carts() |> hd()

# Inspect updated cart totals
Carts.get_cart_by_id(cart.id)

# Remove items
Carts.remove_item_from_cart(cart.id, coffee.id, 1)

# View items
CartsItem.get_items_by_cart(cart.id)
```

## Running Tests

```bash
mix test
```

## Design Notes

- Totals recalculation: A single `recompute_totals!/1` function queries current `cart_items`, aggregates gross (Σ quantity × list_unit_price), calculates promotional discounts, and persists `gross_total`, `discounts`, `net_total` in one DB write.
- Promotions live in `Specials` and are SKU‑driven, making the rule engine easily extendable.
- All cart mutations run inside `Repo.transaction/1` with `Repo.rollback/1` used to surface domain error tuples cleanly.
- Money is represented with `Decimal`.

## Common Errors

| Error Tuple                        | Meaning                                    |
| ---------------------------------- | ------------------------------------------ |
| `{:error, :invalid_quantity}`      | Quantity <= 0 on add/remove                |
| `{:error, :cart_not_found}`        | Cart id absent                             |
| `{:error, :product_not_found}`     | Product id absent on add                   |
| `{:error, :item_not_found}`        | Removing product not currently in cart     |
| `{:error, :insufficient_quantity}` | Attempted removal exceeds quantity present |

## Development Tips / Aliases

- `mix ecto.reset` – drop, create, migrate, seed (alias defined in `mix.exs`).
- Use `iex -S mix` for live experimentation.
- Add new special rules inside `Specials.calc_line_discounts/1` following the existing pattern (map keyed by SKU).
