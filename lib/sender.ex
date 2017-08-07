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

  def handle_call({:send_message, token, text}, _from, pid) do
    notification = %{aps: %{alert: text}}
    headers = %{apns_id: UUID.uuid1(),
                apns_expiration: "0",
                apns_priority: "10",
                apns_topic: "network.potato.Gratin",
                apns_collapse_id: "potato.messages"}
    {200, [{"apns-id", id}], :no_body}  = :apns.push_notification pid, token, notification, headers
    {:reply, {:ok, id}, pid}
  end

  def init(:ok) do
    {:ok, pid} = :apns.connect :cert, :dev_config
    {:ok, pid}
  end

  def send_message(token, text) do
    GenServer.call PotatoApns.Sender, {:send_message, token, text}
  end

  def test_send do
    send_message("E23E2C1974B78550D39561473512D27D73512C97A24F416584B8125369446D2E", "test test")
  end
end
