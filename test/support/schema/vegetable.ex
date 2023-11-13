defmodule MyApp.Schema.Vegetable do
  @moduledoc """
  Defines an Ecto schema for testing.
  """
  use Ecto.Schema

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "vegetables" do
    field(:name, :string)
    field(:family, :string)
  end
end
