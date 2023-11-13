defmodule MyApp.Schema.Pet do
  @moduledoc """
  Defines an Ecto schema for testing.
  """
  use Ecto.Schema

  alias MyApp.Schema.Owner

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "pets" do
    field(:age, :integer)
    field(:family_name, :string)
    field(:given_name, :string)
    field(:name, :string)
    field(:species, :string)
    field(:mood, Ecto.Enum, values: [:happy, :relaxed, :playful])
    field(:tags, {:array, :string}, default: [])

    belongs_to :owner, Owner
  end

  # def test_custom_filter(query, %Flop.Filter{value: value} = filter, opts) do
  #   :options = Keyword.fetch!(opts, :some)
  #   send(self(), {:filter, {filter, opts}})

  #   if value == "some_value" do
  #     where(query, false)
  #   else
  #     query
  #   end
  # end

  # def reverse_name_filter(query, %Flop.Filter{value: value}, _) do
  #   reversed = value
  #   where(query, [p], p.name == ^reversed)
  # end

  # def get_field(%__MODULE__{owner: %Owner{age: age}}, :owner_age), do: age
  # def get_field(%__MODULE__{owner: nil}, :owner_age), do: nil
  # def get_field(%__MODULE__{owner: %Owner{name: name}}, :owner_name), do: name
  # def get_field(%__MODULE__{owner: nil}, :owner_name), do: nil
  # def get_field(%__MODULE__{owner: %Owner{tags: tags}}, :owner_tags), do: tags
  # def get_field(%__MODULE__{owner: nil}, :owner_tags), do: nil

  # def get_field(%__MODULE__{} = pet, field)
  #     when field in [:name, :age, :species, :tags],
  #     do: Map.get(pet, field)

  # def get_field(%__MODULE__{} = pet, field)
  #     when field in [:full_name, :pet_and_owner_name],
  #     do: random_value_for_compound_field(pet, field)

  # def random_value_for_compound_field(
  #       %__MODULE__{family_name: family_name, given_name: given_name},
  #       :full_name
  #     ),
  #     do: Enum.random([family_name, given_name])

  # def random_value_for_compound_field(
  #       %__MODULE__{name: name, owner: %Owner{name: owner_name}},
  #       :pet_and_owner_name
  #     ),
  #     do: Enum.random([name, owner_name])

  # def concatenated_value_for_compound_field(
  #       %__MODULE__{family_name: family_name, given_name: given_name},
  #       :full_name
  #     ),
  #     do: family_name <> " " <> given_name

  # def concatenated_value_for_compound_field(
  #       %__MODULE__{name: name, owner: %Owner{name: owner_name}},
  #       :pet_and_owner_name
  #     ),
  #     do: name <> " " <> owner_name
end
