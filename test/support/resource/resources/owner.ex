defmodule MyApp.Thing.Owner do
  @moduledoc """
  Defines an Ecto schema for testing.
  """
  use Ash.Resource, data_layer: AshPostgres.DataLayer

  alias MyApp.Thing.Pet

  @derive {
    Flop.Schema,
    filterable: [:name], sortable: [:name, :age], default_pagination_type: :page
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
