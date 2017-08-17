defmodule PotatoApns.Sender do
  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  def handle_info({:connection_up, _}, pid) do
    IO.puts "apns connection up"
    {:noreply, pid}
  end

  def handle_info({:reconnecting, _}, pid) do
    IO.puts "apns reconnecting"
    {:noreply, pid}
  end

  defp connect do
    :apns.connect(:cert, :dev_config)
  end

  defp attempt_send(pid, token, text, extra) do
    notification = %{aps: %{alert: text,
                            extra: extra}}
    headers = %{apns_id: UUID.uuid1(),
                apns_expiration: "0",
                apns_priority: "10",
                apns_topic: "network.potato.Gratin",
                apns_collapse_id: "message_notification"}
    res = :apns.push_notification(pid, token, notification, headers)
    IO.puts "Got result from push notification: #{inspect(res)}"
    case res do
      {200, [{"apns-id", id}], :no_body} ->
        {:call_reply, {:ok, id}}
      {400, [{"apns-id", _id}], _body} ->
        {:call_reply, {:error, {:token_invalid, token}}}
      {:timeout, time} ->
        {:call_timeout, time}
    end
  end

  def handle_call({:send_message, token, text, extra}, _from, pid) do
    res = attempt_send(pid, token, text, extra)
    IO.puts "After first attempt to send: #{inspect(res)}"
    case res do
      {:call_reply, status} ->
        {:reply, status, pid}
      {:call_timeout, time} ->
        IO.puts "Connection timed out, time = #{time}. Killing connection and attempting redelivery."
        :apns.close_connection pid
        {:ok, pid} = connect()
        res = attempt_send(pid, token, text, extra)
        IO.puts "After second attempt to send: #{inspect(res)}"
        {:call_reply, status} = res
        {:reply, status, pid}
    end
  end

  def init(:ok) do
    case connect() do
      {:ok, pid} ->
        {:ok, pid}
      {:error, {:already_started, pid}} ->
        :apns.close_connection pid
        :timer.sleep(1000)
        init(:ok)
    end
  end

  def send_message(token, text, extra) do
    GenServer.call PotatoApns.Sender, {:send_message, token, text, extra}, 45 * 1000
  end

  def test_send do
    send_message("E23E2C1974B78550D39561473512D27D73512C97A24F416584B8125369446D2E", "test test",
      %{"channel" => "xyz", "foo" => "blah"})
  end
end
