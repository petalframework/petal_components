defmodule Mix.Tasks.Heroicons.Generate do
  use Mix.Task

  @shortdoc "Convert source SVG files into heex components. Run `git clone https://github.com/tailwindlabs/heroicons.git` first."
  def run(_) do
    Enum.each(["outline", "solid"], &loop_directory/1)

    Mix.Task.run("format")
  end

  defp loop_directory(folder) do
    src_path = "./heroicons/optimized/#{folder}/"
    namespace = "Heroicons.#{String.capitalize(folder)}"

    file_content = """
    defmodule PetalComponents.#{namespace} do
      use Phoenix.Component
      @moduledoc \"\"\"
      Icon name can be the function or passed in as a type eg.
      <PetalComponents.Heroicons.Solid.home class="w-5 h-5" />
      <PetalComponents.Heroicons.Solid.render type="home" class="w-5 h-5" />

      <PetalComponents.Heroicons.Outline.home class="w-6 h-6" />
      <PetalComponents.Heroicons.Outline.render type="home" class="w-6 h-6" />
      \"\"\"

      def render(assigns) do
        icon_name = assigns.icon
        apply(__MODULE__, icon_name, [assigns])
      end

    """

    functions_content =
      src_path
      |> File.ls!()
      |> Enum.filter(&(Path.extname(&1) == ".svg"))
      |> Enum.sort()
      |> Enum.map(&create_component(src_path, &1, folder))
      |> Enum.join("\n\n")

    file_content =
      file_content <>
        functions_content <>
        """

        end
        """

    dest_path = "./lib/petal_components/icons/heroicons/#{folder}.ex"

    unless File.exists?(dest_path) do
      File.mkdir_p("./lib/petal_components/icons/heroicons")
    end

    File.write!(dest_path, file_content)
  end

  defp create_component(src_path, filename, type) do
    svg_content =
      File.read!(Path.join(src_path, filename))
      |> String.trim()
      |> String.replace(~r/<svg /, "<svg class={@class} {@extra_assigns} ")
      |> String.replace(~r/<path/, "  <path")

    build_component(filename, svg_content, type)
  end

  defp function_name(current_filename) do
    current_filename
    |> Path.basename(".svg")
    |> String.replace("-", "_")
  end

  defp build_component(filename, svg, type) do
    class = class_for(type)

    """
    def #{function_name(filename)}(assigns) do
      assigns = assigns
        |> assign_new(:class, fn -> "#{class}" end)
        |> assign_new(:extra_assigns, fn ->
          assigns_to_attributes(assigns, ~w(
            class
          )a)
        end)

      ~H\"\"\"
      #{svg}
      \"\"\"
    end
    """
  end

  defp class_for("outline"), do: "h-6 w-6"
  defp class_for("solid"), do: "h-5 w-5"
end
