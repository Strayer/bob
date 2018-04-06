defmodule Bob.Job.BuildElixir do
  require Logger

  def run([event, ref]) do
    directory = Bob.Directory.new()
    Logger.info("Using directory #{directory}")
    Bob.Script.run({:script, "build_elixir_docker.sh"}, [event, ref], directory)
  end

  def equal?(args1, args2), do: args1 == args2
end
