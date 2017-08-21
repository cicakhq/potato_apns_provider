defmodule PotatoApns.QueueReader do
  use GenServer

  defmodule Connection do
    defstruct channel: "", provider: ""
  end

  def start_link(opts) do
    GenServer.start_link(__MODULE__, {:ok, "apns"}, opts)
  end

  @exchange "apns-sender-ex"
  @queue "apns-sender"

  def init({:ok, provider_name}) do
    rabbitmq_connect(provider_name)
  end

  defp rabbitmq_connect(provider_name) do
    case AMQP.Connection.open(host: "10.137.2.26") do
      {:ok, conn} ->
        name = @queue <> "-" <> provider_name

        {:ok, channel} = AMQP.Channel.open(conn)
        {:ok, queue} = AMQP.Queue.declare(channel, name, [arguments: [{"x-message-ttl", :long, 60 * 60 * 1000}]])

        queue_name = queue.queue
        IO.puts "Queue name: #{queue_name}"

        :ok = AMQP.Queue.bind(channel, queue_name, @exchange, [routing_key: "*." <> provider_name])
        {:ok, _ctag} = AMQP.Basic.consume(channel, queue_name)
        {:ok, %Connection{channel: channel, provider: provider_name}}
      {:error, _} ->
        :timer.sleep(10000)
        rabbitmq_connect(provider_name)
    end
  end

  def handle_info({:DOWN, conn, :process, _pid, _reason}, _) do
    {:ok, conn} = rabbitmq_connect(conn.provider)
    {:noreply, conn}
  end

  def handle_info({:basic_consume_ok, %{consumer_tag: _consumer_tag}}, conn) do
    IO.puts "consumer registered"
    {:noreply, conn}
  end

  def handle_info({:basic_cancel, %{consumer_tag: _consumer_tag}}, conn) do
    IO.puts "consumer cancelled by error"
    {:stop, :normal, conn}
  end

  def handle_info({:basic_cancel_ok, %{consumer_tag: _consumer_tag}}, conn) do
    IO.puts "normal cancel"
    {:noreply, conn}
  end

  def handle_info({:basic_deliver, payload, %{delivery_tag: tag, redelivered: redelivered}}, conn) do
    spawn fn -> consume(conn.channel, tag, redelivered, payload) end
    {:noreply, conn}
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
    result = PotatoApns.Sender.send_message(parsed["token"], "Message from #{sender_name}", extra)
    IO.puts "In queuereader, result from send_message: #{inspect(result)}"
    case result do
      {:ok, _id} ->
        :ok
      {:error, {:token_invalid, token}} ->
        IO.puts "Should unregister token #{token} here"
        :ok
    end
  end
end
