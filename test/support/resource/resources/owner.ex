defmodule MyApp.Thing.Owner do
  @moduledoc """
  Defines an Ecto schema for testing.
  """
  use Ash.Resource, data_layer: AshPostgres.DataLayer

  alias MyApp.Thing.Pet

  @derive {
    Flop.Schema,
    filterable: [:name, :pet_mood_as_reference, :pet_mood_as_enum],
    sortable: [:name, :age],
    join_fields: [
      pet_age: {:pets, :age},
      pet_mood_as_reference: [
        binding: :pets,
        field: :mood,
        ecto_type: {:from_schema, Pet, :mood}
      ],
      pet_mood_as_enum: [
        binding: :pets,
        field: :mood,
        ecto_type: {:ecto_enum, [:happy, :playful]}
      ]
    ],
    compound_fields: [age_and_pet_age: [:age, :pet_age]],
    alias_fields: [:pet_count],
    default_pagination_type: :page
  }

  postgres do
    table "owners"
    repo(FlopAshAdapter.Repo)
  end

  actions do
    defaults [:create, :read]
  end

  attributes do
    uuid_primary_key :id
    attribute :age, :integer
    attribute :email, :string
    attribute :name, :string
    attribute :tags, {:array, :string}, default: []
    attribute :attributes, :map
    attribute :extra, :map
  end

  relationships do
    has_many :pets, Pet
  end

  aggregates do
    count :pet_count, :pets
  end

  # calculations do
  #   calculate :pet_count, :integer, Ash.count(pets)
  # end
end
