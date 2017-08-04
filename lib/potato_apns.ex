defmodule PotatoApns do
  use Application

  def start(type, args) do
    IO.puts "Starting application. type=#{inspect(type)}, args=#{inspect(args)}"
    PotatoApns.Supervisor.start_link(name: PotatoApns.Supervisor)
  end
end
