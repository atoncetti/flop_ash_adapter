defmodule MyApp.Schema.Owner do
  @moduledoc """
  Defines an Ecto schema for testing.
  """
  use Ecto.Schema

  alias MyApp.Schema.Pet

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "owners" do
    field(:age, :integer)
    field(:email, :string)
    field(:name, :string)
    field(:tags, {:array, :string}, default: [])
    field(:attributes, :map)
    field(:extra, {:map, :string})

    has_many :pets, Pet
  end
end
