defmodule FlopAshAdapter.TestUtil do
  @moduledoc false

  import FlopAshAdapter.Factory

  alias Ash.Query
  alias Ecto.Adapters.SQL.Sandbox
  alias Flop.FieldInfo
  alias FlopAshAdapter.Repo
  alias MyApp.Thing
  alias MyApp.Thing.Fruit
  alias MyApp.Thing.Pet

  @adapter FlopAshAdapter

  def checkin_checkout do
    :ok = Sandbox.checkin(Repo)
    :ok = Sandbox.checkout(Repo)
  end

  @doc """
  Takes a list of items and applies filter operators on the list using
  `Enum.filter/2`.

  The function supports regular fields, join fields and compound fields. The
  associations need to be preloaded if join fields are used.
  """
  def filter_items(items, field, op, value \\ nil)

  def filter_items([], _, _, _), do: []

  def filter_items([%module{} = struct | _] = items, field, op, value)
      when is_atom(field) do
    struct
    |> Flop.Schema.field_info(field)
    |> case do
      # %FieldInfo{ecto_type: ecto_type, extra: %{type: :join}} = field_info
      # when not is_nil(ecto_type) ->
      #   filter_func = matches?(op, value, ecto_type)

      #   Enum.filter(items, fn item ->
      #     item |> get_field(field_info) |> filter_func.()
      #   end)

      %FieldInfo{extra: %{type: type}} = field_info
      when type in [:normal, :join] ->
        ecto_type = module.__schema__(:type, field)
        filter_func = matches?(op, value, ecto_type)

        Enum.filter(items, fn item ->
          item |> get_field(field_info) |> filter_func.()
        end)

      %FieldInfo{extra: %{type: :compound, fields: fields}} ->
        Enum.filter(
          items,
          &apply_filter_to_compound_fields(&1, fields, op, value)
        )
    end
    |> clean_ash_metafields()
  end

  defp apply_filter_to_compound_fields(_pet, _fields, op, _value)
       when op in [
              :==,
              :=~,
              :<=,
              :<,
              :>=,
              :>,
              :in,
              :not_in,
              :contains,
              :not_contains
            ] do
    true
  end

  defp apply_filter_to_compound_fields(pet, fields, :empty, value) do
    filter_func = matches?(:empty, value)

    Enum.all?(fields, fn field ->
      field_info = Flop.Schema.field_info(%Pet{}, field)
      pet |> get_field(field_info) |> filter_func.()
    end)
  end

  defp apply_filter_to_compound_fields(pet, fields, :like_and, value) do
    value = if is_binary(value), do: String.split(value), else: value

    Enum.all?(value, fn substring ->
      filter_func = matches?(:like, substring)

      Enum.any?(fields, fn field ->
        field_info = Flop.Schema.field_info(%Pet{}, field)
        pet |> get_field(field_info) |> filter_func.()
      end)
    end)
  end

  defp apply_filter_to_compound_fields(pet, fields, :ilike_and, value) do
    value = if is_binary(value), do: String.split(value), else: value

    Enum.all?(value, fn substring ->
      filter_func = matches?(:ilike, substring)

      Enum.any?(fields, fn field ->
        field_info = Flop.Schema.field_info(%Pet{}, field)
        pet |> get_field(field_info) |> filter_func.()
      end)
    end)
  end

  defp apply_filter_to_compound_fields(pet, fields, :like_or, value) do
    value = if is_binary(value), do: String.split(value), else: value

    Enum.any?(value, fn substring ->
      filter_func = matches?(:like, substring)

      Enum.any?(fields, fn field ->
        field_info = Flop.Schema.field_info(%Pet{}, field)
        pet |> get_field(field_info) |> filter_func.()
      end)
    end)
  end

  defp apply_filter_to_compound_fields(pet, fields, :ilike_or, value) do
    value = if is_binary(value), do: String.split(value), else: value

    Enum.any?(value, fn substring ->
      filter_func = matches?(:ilike, substring)

      Enum.any?(fields, fn field ->
        field_info = Flop.Schema.field_info(%Pet{}, field)
        pet |> get_field(field_info) |> filter_func.()
      end)
    end)
  end

  defp apply_filter_to_compound_fields(pet, fields, op, value) do
    filter_func = matches?(op, value)

    Enum.any?(fields, fn field ->
      field_info = Flop.Schema.field_info(%Pet{}, field)
      pet |> get_field(field_info) |> filter_func.()
    end)
  end

  defp get_field(pet, %FieldInfo{extra: %{type: :normal, field: field}}),
    do: Map.fetch!(pet, field)

  defp get_field(pet, %FieldInfo{extra: %{type: :join, path: [a, b]}}),
    do: pet |> Map.fetch!(a) |> Map.fetch!(b)

  defp matches?(op, v, _), do: matches?(op, v)
  defp matches?(:==, v), do: &(&1 == v)
  defp matches?(:!=, v), do: &(&1 != v)
  defp matches?(:empty, _), do: &empty?(&1)
  defp matches?(:not_empty, _), do: &(!empty?(&1))
  defp matches?(:<=, v), do: &(&1 <= v)
  defp matches?(:<, v), do: &(&1 < v)
  defp matches?(:>, v), do: &(&1 > v)
  defp matches?(:>=, v), do: &(&1 >= v)
  defp matches?(:in, v), do: &(&1 in v)
  defp matches?(:not_in, v), do: &(&1 not in v)
  defp matches?(:contains, v), do: &(v in &1)
  defp matches?(:not_contains, v), do: &(v not in &1)
  defp matches?(:like, v), do: &(&1 =~ v)
  defp matches?(:not_like, v), do: &(&1 =~ v == false)
  defp matches?(:=~, v), do: matches?(:ilike, v)

  defp matches?(:ilike, v) do
    v = String.downcase(v)
    &(String.downcase(&1) =~ v)
  end

  defp matches?(:not_ilike, v) do
    v = String.downcase(v)
    &(String.downcase(&1) =~ v == false)
  end

  defp matches?(:like_and, v) when is_binary(v) do
    values = String.split(v)
    &Enum.all?(values, fn v -> &1 =~ v end)
  end

  defp matches?(:like_and, v), do: &Enum.all?(v, fn v -> &1 =~ v end)

  defp matches?(:like_or, v) when is_binary(v) do
    values = String.split(v)
    &Enum.any?(values, fn v -> &1 =~ v end)
  end

  defp matches?(:like_or, v), do: &Enum.any?(v, fn v -> &1 =~ v end)

  defp matches?(:ilike_and, v) when is_binary(v) do
    values = v |> String.downcase() |> String.split()
    &Enum.all?(values, fn v -> String.downcase(&1) =~ v end)
  end

  defp matches?(:ilike_and, v) do
    values = Enum.map(v, &String.downcase/1)
    &Enum.all?(values, fn v -> String.downcase(&1) =~ v end)
  end

  defp matches?(:ilike_or, v) when is_binary(v) do
    values = v |> String.downcase() |> String.split()
    &Enum.any?(values, fn v -> String.downcase(&1) =~ v end)
  end

  defp matches?(:ilike_or, v) do
    values = Enum.map(v, &String.downcase/1)
    &Enum.any?(values, fn v -> String.downcase(&1) =~ v end)
  end

  defp empty?(nil), do: true
  defp empty?([]), do: true
  defp empty?(map) when map == %{}, do: true
  defp empty?(_), do: false

  @doc """
  Removes Ash meta fields from an Ash resource or list of ash resources.
  """
  def clean_ash_metafields(resources) when is_list(resources),
    do: Enum.map(resources, &clean_ash_metafields/1)

  def clean_ash_metafields(resource) when is_struct(resource),
    do: Map.delete(resource, :__metadata__)

  def insert_list_and_convert(count, factory, args \\ [])

  def insert_list_and_convert(count, factory, args)
      when factory in [:pet, :pet_with_owner, :pet_downcase] do
    count
    |> insert_list(factory, args)

    Pet
    |> Ash.Query.load([
      :owner,
      :owner_name,
      :owner_age,
      :owner_tags,
      :full_name,
      :pet_and_owner_name,
      :reverse_name
    ])
    |> Thing.read!()
  end

  def insert_list_and_convert(count, :fruit, args) do
    count
    |> insert_list(:fruit, args)

    Fruit
    |> Ash.Query.load([:owner, :owner_attributes, :owner_extra])
    |> Thing.read!()
  end

  @doc """
  Inserts a list of items using `FlopAshAdapter.Factory` and sorts the list by `:id`
  field.
  """
  def insert_list_and_sort(count, factory, args \\ [])

  def insert_list_and_sort(count, :pet, args) do
    count
    |> insert_list_and_convert(:pet, args)
    |> Enum.sort_by(& &1.id)
  end

  def insert_list_and_sort(count, :pet_with_owner, args) do
    count
    |> insert_list_and_convert(:pet_with_owner, args)
    |> Enum.sort_by(& &1.id)
  end

  def insert_list_and_sort(count, :pet_downcase, args) do
    count
    |> insert_list_and_convert(:pet_downcase, args)
    |> Enum.sort_by(& &1.id)
  end

  def insert_list_and_sort(count, :fruit, args) do
    count
    |> insert_list_and_convert(:fruit, args)
    |> Enum.sort_by(& &1.id)
  end

  @doc """
  Query that returns all pets with owners joined and preloaded.
  """
  def pets_with_owners_query do
    Ash.Query.load(Pet, [
      :owner,
      :owner_name,
      :owner_age,
      :owner_tags,
      :full_name,
      :pet_and_owner_name
    ])
  end

  @doc """
  Queries all pets using `Flop.all`. Preloads the owners and sorts by Pet ID.
  """
  def query_pets_with_owners(params, opts \\ []) do
    flop =
      Flop.validate!(params,
        for: Pet,
        adapter: @adapter,
        api: Thing,
        max_limit: 999_999_999,
        default_limit: 999_999_999
      )

    sort? = opts[:sort] || true

    q =
      Query.load(Pet, [
        :owner,
        :owner_name,
        :owner_age,
        :owner_tags,
        :full_name,
        :pet_and_owner_name,
        :reverse_name
      ])

    q = if sort?, do: Query.sort(q, [:id]), else: q

    opts =
      opts
      |> Keyword.take([:extra_opts])
      |> Keyword.merge(for: Pet, adapter: @adapter, api: Thing)

    q |> Flop.all(flop, opts) |> clean_ash_metafields()
  end

  @doc """
  Queries all fruits using `Flop.all`. Preloads the owners and sorts by
  Fruit ID.
  """
  def query_fruits_with_owners(params, opts \\ []) do
    flop =
      Flop.validate!(params,
        for: Fruit,
        adapter: @adapter,
        api: Thing,
        max_limit: 999_999_999,
        default_limit: 999_999_999
      )

    sort? = opts[:sort] || true

    q = Query.load(Fruit, [:owner, :owner_attributes, :owner_extra])
    q = if sort?, do: Query.sort(q, [:id]), else: q

    opts =
      opts
      |> Keyword.take([:extra_opts])
      |> Keyword.merge(for: Fruit, adapter: @adapter, api: Thing)

    q |> Flop.all(flop, opts) |> clean_ash_metafields()
  end

  @doc """
  A helper that transforms changeset errors into a map of messages.

      assert {:error, changeset} = Accounts.create_user(%{password: "short"})
      assert "password is too short" in errors_on(changeset).password
      assert %{password: ["password is too short"]} = errors_on(changeset)

  Brought to you by Phoenix.
  """
  def errors_on(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {message, opts} ->
      Regex.replace(~r"%{(\w+)}", message, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end
end
