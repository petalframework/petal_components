defmodule PetalComponents do
  defmacro __using__(_) do
    quote do
      import PetalComponents.{
        Accordion,
        Alert,
        Avatar,
        Badge,
        Breadcrumbs,
        Button,
        Card,
        Container,
        Dropdown,
        Field,
        Form,
        Icon,
        Input,
        Link,
        Loading,
        Modal,
        Pagination,
        Progress,
        Rating,
        SlideOver,
        Table,
        Tabs,
        Typography,
        UserDropdownMenu,
        Menu
      }

      alias PetalComponents.HeroiconsV1
    end
  end
end
