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
      # :custom,
      :reverse_name
    ],
    sortable: [:name, :age, :owner_name, :owner_age],
    max_limit: 1000
    # adapter_opts: [
    #   compound_fields: [
    #     full_name: [:family_name, :given_name],
    #     pet_and_owner_name: [:name, :owner_name]
    #   ],
    #   join_fields: [
    #     owner_age: {:owner, :age},
    #     owner_name: [
    #       binding: :owner,
    #       field: :name,
    #       path: :owner_name,
    #       ecto_type: :string
    #     ],
    #     owner_tags: [
    #       binding: :owner,
    #       field: :tags,
    #       ecto_type: {:array, :string}
    #     ]
    #   ],
    #   custom_fields: [
    #     custom: [
    #       filter: {__MODULE__, :test_custom_filter, [some: :options]},
    #       operators: [:==]
    #     ],
    #     reverse_name: [
    #       filter: {__MODULE__, :reverse_name_filter, []},
    #       ecto_type: :string
    #     ]
    #   ]
    # ]
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
