defmodule CashierTest do
  use ExUnit.Case
  doctest Cashier

  test "greets the world" do
    assert Cashier.hello() == :world
  end
end
