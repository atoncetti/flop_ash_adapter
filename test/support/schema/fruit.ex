defmodule MyApp.Schema.Fruit do
  @moduledoc """
  Defines an Ecto schema for testing.
  """
  use Ecto.Schema

  alias MyApp.Schema.Owner

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "fruits" do
    field(:name, :string)
    field(:family, :string)
    field(:attributes, :map)
    field(:extra, {:map, :string})

    belongs_to :owner, Owner
  end
end
