defmodule PotatoApns.QueueReader do
  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  @exchange "apns-sender-ex"
  @queue "apns-sender"

  def init(:ok) do
    rabbitmq_connect()
  end

  defp rabbitmq_connect do
    case AMQP.Connection.open(host: "10.137.2.26") do
      {:ok, conn} ->
        {:ok, channel} = AMQP.Channel.open(conn)
        {:ok, queue} = AMQP.Queue.declare(channel, @queue, [arguments: [{"x-message-ttl", :long, 60 * 60 * 1000}]])

        queue_name = queue.queue
        IO.puts "Queue name: #{queue_name}"

        :ok = AMQP.Queue.bind(channel, queue_name, @exchange, [routing_key: "#"])
        {:ok, _ctag} = AMQP.Basic.consume(channel, queue_name)
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
    parsed = Poison.decode!(payload)
    IO.puts "Got message: #{inspect(parsed)}"

    sender_name = parsed["sender_name"]
    extra = %{"channel" => parsed["channel"],
              "message_id" => parsed["message_id"],
              "notification_type" => parsed["notification_type"],
              "sender_id" => parsed["sender_id"],
              "sender_name" => sender_name,
              "text" => parsed["text"]}
    case PotatoApns.Sender.send_message(parsed["token"], "Message from #{sender_name}", extra) do
      {:ok, _id} ->
        :ok
      {:error, {:token_invalid, token}} ->
        IO.puts "Should unregister token #{token} here"
        :ok
    end

  end
end
