defmodule FlopAshAdapter.NoApiError do
  defexception [:function_name]

  def message(%{function_name: function_name}) do
    """
    no Ash api configured

    You attempted to call `Flop.#{function_name}/3` (or its equivalent in a Flop
    backend module), but no Ash api was specified.

    Specify the api in one of the following ways.

    Explicitly pass the api to the function:

        Flop.#{function_name}(MyApp.Item, %Flop{}, repo: MyApp.Repo)

    Define a backend module and pass the Ash api as an option:

        defmodule MyApp.Flop do
          use Flop, api: MyApp.ResourceApi
        end
    """
  end
end
