defmodule MyApp.Thing.Pet do
  @moduledoc """
  Defines an Ash resource for testing.
  """
  use Ash.Resource, data_layer: AshPostgres.DataLayer

  alias MyApp.Thing.Owner

  @derive {
    Flop.Schema,
    filterable: [
      :age,
      :full_name,
      :mood,
      :name,
      :owner_age,
      :owner_name,
      :owner_tags,
      :pet_and_owner_name,
      :species,
      :tags,
      :reverse_name
    ],
    sortable: [:name, :age, :owner_name, :owner_age],
    max_limit: 1000
  }

  postgres do
    table "pets"
    repo(FlopAshAdapter.Repo)
  end

  actions do
    defaults [:create, :read]
  end

  attributes do
    uuid_primary_key :id
    attribute :age, :integer
    attribute :family_name, :string
    attribute :given_name, :string
    attribute :name, :string
    attribute :species, :string
    attribute :mood, :atom, constraints: [one_of: [:happy, :relaxed, :playful]]
    attribute :tags, {:array, :string}
  end

  relationships do
    belongs_to :owner, Owner
  end

  calculations do
    calculate :full_name, :string, expr(family_name <> " " <> given_name)
    calculate :pet_and_owner_name, :string, expr(name <> " " <> owner.name)
    calculate :owner_name, :string, expr(owner.name)
    calculate :owner_age, :integer, expr(owner.age)
    calculate :owner_tags, {:array, :string}, expr(owner.tags)
    calculate :reverse_name, :string, expr(name)
  end

  def get_field(%{owner: %{age: age}}, :owner_age), do: age
  def get_field(%{owner: nil}, :owner_age), do: nil
  def get_field(%{owner: %{name: name}}, :owner_name), do: name
  def get_field(%{owner: nil}, :owner_name), do: nil
  def get_field(%{owner: %{tags: tags}}, :owner_tags), do: tags
  def get_field(%{owner: nil}, :owner_tags), do: nil

  def get_field(%{} = pet, field)
      when field in [:name, :age, :species, :tags],
      do: Map.get(pet, field)

  def get_field(%{} = pet, field)
      when field in [:full_name, :pet_and_owner_name],
      do: random_value_for_compound_field(pet, field)

  def random_value_for_compound_field(
        %{family_name: family_name, given_name: given_name},
        :full_name
      ),
      do: Enum.random([family_name, given_name])

  def random_value_for_compound_field(
        %{name: name, owner: %{name: owner_name}},
        :pet_and_owner_name
      ),
      do: Enum.random([name, owner_name])
end
