defmodule MyApp.Thing.Registry do
  @moduledoc false

  use Ash.Registry

  entries do
    entry MyApp.Thing.Fruit
    entry MyApp.Thing.Owner
    entry MyApp.Thing.Pet
    entry MyApp.Thing.Vegetable
  end
end
