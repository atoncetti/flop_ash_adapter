defmodule MyApp.Thing.Vegetable do
  @moduledoc """
  Defines an Ash resource for testing.
  """
  use Ash.Resource, data_layer: AshPostgres.DataLayer

  @derive {Flop.Schema,
           filterable: [:name, :family],
           sortable: [:name],
           default_limit: 60,
           default_order: %{
             order_by: [:name],
             order_directions: [:asc]
           },
           pagination_types: [:page]}

  postgres do
    table "vegetables"
    repo(FlopAshAdapter.Repo)
  end

  actions do
    defaults [:create, :read]
  end

  attributes do
    uuid_primary_key :id
    attribute :name, :string
    attribute :family, :string
  end
end
