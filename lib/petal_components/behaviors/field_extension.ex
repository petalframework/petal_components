defmodule PetalComponents.Field.Extension do
  @moduledoc """
  Behavior for field extensions.
  """

  @doc """
  This callback function takes assigns and returns a rendered field's body.

  ## Example
      @behaviour PetalComponents.Field.Extension

      def render(assigns) do
        ~H'''
        <div>Custom Field</div>
        '''
      end
  """
  @callback render(assigns :: map) :: map

  @doc """
  This callback function is used to get classes for the custom field.

  ## Example
      @behaviour PetalComponents.Field.Extension

      def get_class_for_type("pretty_field"), do: "pc-text-input"
  """
  @callback get_class_for_type(String.t) :: String.t

  @optional_callbacks get_class_for_type: 1
end
