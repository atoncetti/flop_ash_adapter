defmodule FlopAshAdapter.Operators do
  @moduledoc false

  # import Ecto.Query

  alias Ash.Filter
  alias AshPostgres.Functions

  def reduce_filter(combinator, values, inner_func) do
    Enum.reduce(values, nil, fn value, base_filter ->
      Filter.add_to_filter!(base_filter, inner_func.(value), combinator)
    end)
  end

  def op_config(:==) do
    quote do
      [{var!(field), [equals: var!(value)]}]
    end
  end

  def op_config(:!=) do
    quote do
      [{var!(field), [not_equals: var!(value)]}]
    end
  end

  def op_config(:>=) do
    quote do
      [{var!(field), [gte: var!(value)]}]
    end
  end

  def op_config(:<=) do
    quote do
      [{var!(field), [lte: var!(value)]}]
    end
  end

  def op_config(:>) do
    quote do
      [{var!(field), [gt: var!(value)]}]
    end
  end

  def op_config(:<) do
    quote do
      [{var!(field), [lt: var!(value)]}]
    end
  end

  def op_config(:empty) do
    empty()
  end

  def op_config(:not_empty) do
    quote do
      [{var!(field), [is_nil: not var!(value)]}]
    end
  end

  def op_config(:in) do
    quote do
      var!(field) in var!(value)
    end
  end

  def op_config(:contains) do
    quote do
      {:ok, contains_expr} = Ash.Query.Operator.In.new(var!(field), [var!(value)])
      Ash.Query.expr(contains_expr)
    end
  end

  def op_config(:not_contains) do
    quote do
      {:ok, contains_expr} = Ash.Query.Operator.In.new(var!(field), [var!(value)])
      Ash.Query.expr(not contains_expr)
    end
  end

  def op_config(:like) do
    quote do
      {:ok, like_expr} = Functions.Like.new([var!(field), Flop.Misc.add_wildcard(var!(value))])
      like_expr
    end
  end

  def op_config(:not_like) do
    quote do
      {:ok, like_expr} = Functions.Like.new([var!(field), Flop.Misc.add_wildcard(var!(value))])
      expr(not like_expr)
    end
  end

  def op_config(:=~) do
    quote do
      {:ok, i_like_expr} = Functions.ILike.new([var!(field), Flop.Misc.add_wildcard(var!(value))])
      i_like_expr
    end
  end

  def op_config(:ilike) do
    quote do
      {:ok, i_like_expr} = Functions.ILike.new([var!(field), Flop.Misc.add_wildcard(var!(value))])
      i_like_expr
    end
  end

  def op_config(:not_ilike) do
    quote do
      {:ok, i_like_expr} = Functions.ILike.new([var!(field), Flop.Misc.add_wildcard(var!(value))])
      expr(not i_like_expr)
    end
  end

  def op_config(:not_in) do
    quote do
      expr(not [{var!(field), [in: var!(value)]}])
    end
  end

  def empty do
    quote do
      [{var!(field), [is_nil: var!(value)]}]
    end
  end

  defmacro empty(:array, value) do
    quote do
      if unquote(value) do
        [
          or: [
            [{var!(field), [is_nil: true]}],
            [{var!(field), [equals: []]}]
          ]
        ]
      else
        [
          and: [
            [{var!(field), [is_nil: false]}],
            [{var!(field), [not_equals: []]}]
          ]
        ]
      end
    end
  end

  defmacro empty(:map, value) do
    quote do
      if unquote(value) do
        [
          or: [
            [{var!(field), [is_nil: true]}],
            [{var!(field), [equals: %{}]}]
          ]
        ]
      else
        [
          and: [
            [{var!(field), [is_nil: false]}],
            [{var!(field), [not_equals: %{}]}]
          ]
        ]
      end
    end
  end

  defmacro empty(:other, value) do
    quote do
      if unquote(value) do
        [{var!(field), [is_nil: true]}]
      else
        [{var!(field), [is_nil: false]}]
      end
    end
  end
end
