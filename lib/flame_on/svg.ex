defmodule FlameOn.SVG do
  use Phoenix.LiveComponent
  alias FlameOn.Parser.Block

  def render(assigns) do
    %Block{} = top_block = Map.fetch!(assigns, :block)

    assigns =
      assigns
      |> assign(:blocks, List.flatten(flatten(top_block)))
      |> assign(:duration_ratio, 1000 / top_block.duration)
      |> assign(:block_height, 25)
      |> assign(:top_block, top_block)

    ~H"""
    <svg width="1000" height={@block_height * top_block.max_child_level}>
    <!-- <%= inspect %Block{@top_block | children: []} %> -->
      <%= for block <- @blocks do %>
        <%= render_flame_on_block(%{block: block, block_height: @block_height, duration_ratio: @duration_ratio, top_block: @top_block, parent: @parent, socket: @socket}) %>
      <% end %>
    </svg>
    """
  end

  defp render_flame_on_block(%{block: %Block{function: nil}}), do: ""

  defp render_flame_on_block(assigns) do
    color = color_for_function(assigns.block.function)

    ~H"""
    <svg width={trunc(@block.duration * @duration_ratio)} height={@block_height} x={(@block.absolute_start - @top_block.absolute_start) * @duration_ratio} y={(@block.level - @top_block.level) * @block_height} phx-click="view_block" phx-target={@parent} phx-value-id={@block.id} style="cursor: pointer;">
      <rect width="100%" height="100%" style={"fill: #{color}; stroke: white;"}></rect>
      <text x={@block_height/4} y={@block_height * 0.5} font-size={@block_height * 0.5} font-family="monospace" dominant-baseline="middle"><%=@block.function %></text>
      <title><%= @block.duration %>&micro;s (<%= trunc((@block.duration * 100) / @top_block.duration) %>%) <%=@block.function %></title>
    </svg>
    """
  end

  defp flatten(%Block{children: children} = block) do
    [block | Enum.map(children, &flatten/1)]
  end

  defp color_for_function("Elixir." <> rest), do: color_for_function(rest)

  defp color_for_function(function) do
    module = function |> String.split(":") |> hd() |> String.split(".") |> hd()
    red = :erlang.phash2(module <> "red", 205) |> Kernel.+(50) |> Integer.to_string(16)
    green = :erlang.phash2(module <> "green", 205) |> Kernel.+(50) |> Integer.to_string(16)
    blue = :erlang.phash2(module <> "blue", 205) |> Kernel.+(50) |> Integer.to_string(16)

    "\##{pad(red)}#{pad(green)}#{pad(blue)}"
  end

  defp pad(str) do
    if String.length(str) == 1 do
      "0" <> str
    else
      str
    end
  end
end
