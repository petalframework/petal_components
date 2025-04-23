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
        ButtonGroup,
        Card,
        Carousel,
        Container,
        Dropdown,
        Field,
        Form,
        Icon,
        Input,
        Link,
        Loading,
        Marquee,
        Modal,
        Pagination,
        Progress,
        Rating,
        Skeleton,
        SlideOver,
        Stepper,
        Table,
        Tabs,
        Typography,
        UserDropdownMenu,
        Menu
      }

      alias PetalComponents.HeroiconsV1
    end
  end

  @default_js_lib Application.compile_env(:petal_components, :default_js_lib, "alpine_js")
  def default_js_lib() do
    @default_js_lib
  end
end
