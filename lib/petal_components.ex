defmodule PetalComponents do
  defmacro __using__(_) do
    quote do
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
        Link,
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
