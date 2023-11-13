defmodule MyApp.Thing do
  @moduledoc false

  use Ash.Api

  resources do
    registry MyApp.Thing.Registry
  end
end
