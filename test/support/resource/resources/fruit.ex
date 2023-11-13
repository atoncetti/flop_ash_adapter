defmodule MyApp.Thing.Fruit do
  @moduledoc """
  Defines an Ash resource for testing.
  """
  use Ash.Resource, data_layer: AshPostgres.DataLayer

  alias MyApp.Thing.Owner

  @derive {Flop.Schema,
           filterable: [
             :name,
             :family,
             :attributes,
             :extra,
             :owner_attributes,
             :owner_extra
           ],
           sortable: [:name],
           default_limit: 60,
           default_order: %{
             order_by: [:name],
             order_directions: [:asc]
           },
           pagination_types: [:first, :last, :offset]}

  postgres do
    table "fruits"
    repo(FlopAshAdapter.Repo)
  end

  actions do
    defaults [:create, :read]
  end

  attributes do
    uuid_primary_key :id
    attribute :name, :string
    attribute :family, :string
    attribute :attributes, :map
    attribute :extra, :map
  end

  relationships do
    belongs_to :owner, Owner
  end

  calculations do
    calculate :owner_attributes, :string, expr(first(owner, field: :attributes))
    calculate :owner_extra, :map, expr(first(owner, field: :extra))
  end
end
