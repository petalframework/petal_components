defmodule PetalComponents do
  @moduledoc """
  In <your_app>_web.ex you can import all Petal Components with:

      use PetalComponents

  If you also want to use our <.link> component, you will need to import it separately:

      use PetalComponents
      import PetalComponents.Link
  """
  defmacro __using__(which \\ nil) do
    quote do
      alias PetalComponents.Heroicons

      import PetalComponents.{
        Alert,
        Badge,
        Button,
        Container,
        Dropdown,
        Form,
        Loading,
        Typography,
        Avatar,
        Progress,
        Breadcrumbs,
        Pagination,
        Modal,
        SlideOver,
        Tabs,
        Card,
        Table,
        Accordion
      }
    end
  end
end
