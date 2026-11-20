defmodule Mix.Tasks.Pnpm do
  @shortdoc "Runs pnpm in the assets directory"

  @moduledoc """
  Runs `pnpm` with the given arguments in the `assets` directory.

      $ mix pnpm install
      $ mix pnpm exec vite build

  `MIX_BUILD_PATH` is set to the current Mix build path so that
  `assets/vite.config.mjs` can resolve the Phoenix LiveView colocated hooks
  and CSS that are generated when the application is compiled.

  The `:vite` watcher in `config/dev.exs` calls `run/1` to start the Vite
  dev server alongside `mix phx.server`.
  """

  use Mix.Task

  @impl Mix.Task
  def run(args) do
    assets_path = Path.join(Path.dirname(Mix.Project.project_file()), "assets")

    {_, status} =
      System.cmd("pnpm", args,
        cd: assets_path,
        env: [{"MIX_BUILD_PATH", Mix.Project.build_path()}],
        into: IO.stream(:stdio, :line),
        stderr_to_stdout: true
      )

    if status != 0 do
      Mix.raise("pnpm #{Enum.join(args, " ")} exited with status #{status}")
    end
  end
end
