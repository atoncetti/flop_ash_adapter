defmodule FlopAshAdapter do
  @moduledoc """
  Impelements the Flop.Adapter behaviour to integrate Ash Framework with Flop.
  """

  @behaviour Flop.Adapter

  import Ash.Query
  import FlopAshAdapter.Operators

  alias Ash.Sort

  alias Flop.FieldInfo
  alias Flop.Filter
  alias Flop.NimbleSchemas

  alias FlopAshAdapter.NoApiError

  require Ash.Sort

  require FlopAshAdapter.Operators
  require Logger

  @operators [
    :==,
    :!=,
    :empty,
    :not_empty,
    :>=,
    :<=,
    :>,
    :<,
    :in,
    :contains,
    :not_contains,
    :like,
    :not_like,
    :=~,
    :ilike,
    :not_ilike,
    :not_in,
    :like_and,
    :like_or,
    :ilike_and,
    :ilike_or
  ]

  @backend_options [
    query_opts: [type: :keyword_list, default: []]
  ]

  @schema_options [
    api: [required: true]
  ]

  @backend_options NimbleOptions.new!(@backend_options)
  @schema_options NimbleOptions.new!(@schema_options)

  defp __backend_options__, do: @backend_options
  defp __schema_options__, do: @schema_options

  @impl Flop.Adapter
  def init_backend_opts(_opts, backend_opts, caller_module) do
    NimbleSchemas.validate!(
      backend_opts,
      __backend_options__(),
      Flop,
      caller_module
    )
  end

  @impl Flop.Adapter
  def init_schema_opts(_opts, schema_opts, caller_module, _struct) do
    NimbleSchemas.validate!(
      schema_opts,
      __schema_options__(),
      Flop.Schema,
      caller_module
    )
  end

  @impl Flop.Adapter
  def fields(struct, _adapter_opts) do
    schema_fields(struct)
  end

  defp schema_fields(%module{} = struct) do
    struct
    |> Map.from_struct()
    |> Enum.reject(fn
      {misc, _any} when misc in [:aggregates, :calculations] -> true
      {:__meta__, _} -> true
      _ -> false
    end)
    |> Enum.map(fn {field, _} ->
      {field,
       %FieldInfo{
         ecto_type: {:from_schema, module, field},
         extra: %{type: :normal, field: field}
       }}
    end)
  end

  @impl Flop.Adapter
  def apply_filter(query, %Flop.Filter{field: field} = filter, schema_struct, _opts) do
    field_info = get_field_info(schema_struct, field)
    filter(query, ^build_op(schema_struct, field_info, filter))
  end

  # Flop gives us directions as [asc: :email], we need [email: :asc]
  @impl Flop.Adapter
  def apply_order_by(query, directions, _opts) do
    do_sort(query, Enum.map(directions, &{elem(&1, 1), elem(&1, 0)}))
  end

  defp do_sort(query, directions) do
    Enum.reduce(directions, query, fn
      {path, direction}, acc_query when is_list(path) ->
        sort(acc_query, Sort.expr_sort(^{path, direction}))

      {[field], direction}, acc_query ->
        sort(acc_query, {field, direction})

      sort_expr, acc_query ->
        sort(acc_query, sort_expr)
    end)
  end

  @impl Flop.Adapter
  def apply_limit_offset(query, limit, offset, _opts) do
    query
    |> limit(limit)
    |> offset(offset)
  end

  @impl Flop.Adapter
  def apply_page_page_size(query, page, page_size, _opts) do
    offset_for_page = (page - 1) * page_size

    query
    |> limit(page_size)
    |> offset(offset_for_page)
  end

  @impl Flop.Adapter
  def apply_cursor(query, cursor_fields, _opts) do
    filter_expression = cursor_filter(cursor_fields)
    filter(query, ^filter_expression)
  end

  defp cursor_filter([]), do: []

  # no cursor value, last cursor field
  defp cursor_filter([{_, _, nil, _}]), do: []

  # no cursor value, more cursor fields to come
  defp cursor_filter([{_, _, nil, _} | [{_, _, _, _} | _] = tail]) do
    cursor_filter(tail)
  end

  # type ascending, last cursor field
  defp cursor_filter([{direction, field, cursor_value, _}])
       when direction in [:asc, :asc_nulls_first, :asc_nulls_last] do
    [{field, [gt: cursor_value]}]
  end

  # type descending, last cursor field
  defp cursor_filter([{direction, field, cursor_value, _}])
       when direction in [:desc, :desc_nulls_first, :desc_nulls_last] do
    [{field, [lt: cursor_value]}]
  end

  # type ascending, more cursor fields to come
  defp cursor_filter([
         {direction, field, cursor_value, _} | [{_, _, _, _} | _] = tail
       ])
       when direction in [:asc, :asc_nulls_first, :asc_nulls_last] do
    [
      and: [
        [{field, [gte: cursor_value]}],
        [or: [[{field, [gt: cursor_value]}], cursor_filter(tail)]]
      ]
    ]
  end

  # type descending, more cursor fields to come
  defp cursor_filter([
         {direction, field, cursor_value, _} | [{_, _, _, _} | _] = tail
       ])
       when direction in [:desc, :desc_nulls_first, :desc_nulls_last] do
    [
      and: [
        [{field, [lte: cursor_value]}],
        [or: [[{field, [lt: cursor_value]}], cursor_filter(tail)]]
      ]
    ]
  end

  @impl Flop.Adapter
  def count(query, opts) do
    apply_using_api(:count!, [query], opts)
  end

  @impl Flop.Adapter
  def list(query, opts) do
    apply_using_api(:read!, [query], opts)
  end

  defp apply_using_api(api_fn, args, opts) do
    api =
      Flop.get_option(:api, opts) ||
        raise NoApiError, function_name: api_fn

    apply(api, api_fn, args)
  end

  @impl Flop.Adapter
  def get_field(%{} = item, field, %FieldInfo{}), do: Map.get(item, field)

  defp get_field_info(nil, field),
    do: %FieldInfo{extra: %{type: :normal, field: field}}

  defp get_field_info(struct, field) when is_atom(field) do
    Flop.Schema.field_info(struct, field)
  end

  # Filter query builder

  for op <- [:like_and, :like_or, :ilike_and, :ilike_or] do
    {field_op, combinator} =
      case op do
        :ilike_and -> {:ilike, :and}
        :ilike_or -> {:ilike, :or}
        :like_and -> {:like, :and}
        :like_or -> {:like, :or}
      end

    defp build_op(
           schema_struct,
           %FieldInfo{extra: %{type: :normal, field: field}},
           %Filter{op: unquote(op), value: value}
         ) do
      field = get_field_info(schema_struct, field)

      values =
        case value do
          v when is_binary(v) -> String.split(v)
          v when is_list(v) -> v
        end

      reduce_filter(unquote(combinator), values, fn substring ->
        expression =
          build_op(schema_struct, field, %Filter{
            field: field,
            op: unquote(field_op),
            value: substring
          })

        %Ash.Filter{expression: expression}
      end)
    end
  end

  defp build_op(
         %module{},
         %FieldInfo{extra: %{type: :normal, field: field}},
         %Filter{op: op, value: value}
       )
       when op in [:empty, :not_empty] do
    ecto_type = module.__schema__(:type, field)
    value = value in [true, "true"]
    value = if op == :not_empty, do: !value, else: value

    case array_or_map(ecto_type) do
      :array ->
        empty(:array, value)

      :map ->
        empty(:map, value)

      :other ->
        empty(:other, value)
    end
  end

  defp array_or_map({:array, _}), do: :array
  defp array_or_map({:parameterized, Ash.Type.Map.EctoType, _}), do: :map
  defp array_or_map(_), do: :other

  for op <- @operators -- [:like_and, :like_or, :ilike_and, :ilike_or] do
    fragment = op_config(op)

    defp build_op(
           _schema_struct,
           %FieldInfo{extra: %{type: :normal, field: field}},
           %Filter{op: unquote(op), value: value}
         ) do
      unquote(fragment)
    end
  end

  @impl Flop.Adapter
  def custom_func_builder(_opts), do: []
end
