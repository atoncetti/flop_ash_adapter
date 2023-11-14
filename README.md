# FlopAshAdapter

A Flop adapter for Ash.

Currently missing:
- empty and not_empty operations on calculations of type array
- like, ilike and combinations {or_, and_}-{like, ilike}
- in and not_in operator
- contains and not_contains operator
- query prefix functionality

## Installation

```elixir
def deps do
  [
    {:flop_ash_adapter, git: "https://github.com/atoncetti/flop_ash_adapter.git", branch: "main"}
  ]
end
```

