defmodule APNS_Listener do
  use GenServer

  def start_link do
    GenServer.start_link(__MODULE__, [], [])
  end

  @exchange "user-notifications-ex"
  @queue "foo"

  def init(_opts) do
    rabbitmq_connect()
  end

  defp rabbitmq_connect do
    case AMQP.Connection.open do
      {:ok, conn} ->
        {:ok, channel} = AMQP.Channel.open(conn)
        {:ok, _} = AMQP.Queue.declare channel, @queue
        :ok = AMQP.Queue.bind channel, @queue, @exchange, [routing_key: "#"]
        {:ok, _ctag} = AMQP.Basic.consume(channel, @queue)
        {:ok, channel}
      {:error, _} ->
        :timer.sleep(10000)
        rabbitmq_connect()
    end
  end

  def handle_info({:DOWN, _, :process, _pid, _reason}, _) do
    {:ok, channel} = rabbitmq_connect()
    {:noreply, channel}
  end

  def handle_info({:basic_consume_ok, %{consumer_tag: _consumer_tag}}, chan) do
    IO.puts "consumer registered"
    {:noreply, chan}
  end

  def handle_info({:basic_cancel, %{consumer_tag: _consumer_tag}}, chan) do
    IO.puts "consumer cancelled by error"
    {:stop, :normal, chan}
  end

  def handle_info({:basic_cancel_ok, %{consumer_tag: _consumer_tag}}, chan) do
    IO.puts "normal cancel"
    {:noreply, chan}
  end

  def handle_info({:basic_deliver, payload, %{delivery_tag: tag, redelivered: redelivered}}, channel) do
    spawn fn -> consume(channel, tag, redelivered, payload) end
    {:noreply, channel}
  end

  defp consume(channel, tag, _redelivered, payload) do
    AMQP.Basic.ack(channel, tag)
    parsed = LispUtil.lisp_plist_to_map(Parser.parse_from_string(payload))
    IO.puts "Got message: #{inspect(parsed)}"
  end
end
