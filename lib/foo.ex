defmodule Foo do
  @moduledoc """
  Documentation for Foo.
  """

  @doc """
  Hello world.

  ## Examples

      iex> Foo.hello
      :world

  """

  @db %{protocol: "http", hostname: "localhost", port: 5984, database: "apns"}

  def hello do
    IO.puts "this is a test message"
    :world
  end

  def handle_notification(payload, _metadata) do
    IO.puts "Got message: #{payload}"
  end

  def amqp_test do
    queue_name = "foo"

    {:ok, conn} = AMQP.Connection.open
    {:ok, channel} = AMQP.Channel.open(conn)
    {:ok, _} = AMQP.Queue.declare channel, queue_name
    :ok = AMQP.Queue.bind channel, queue_name, "user-notifications-ex"
    {:ok, _ctag} = AMQP.Queue.subscribe channel, queue_name, &handle_notification/2
  end

  def couchdb_test do
    # Get a document:
    #   Couchdb.Connector.Reader.get(@db, "foo")

    {:ok, result, _} =
      Couchdb.Connector.Writer.create_generate(@db, Poison.encode!(%{"content" => ["foo", "bar", "z"],
                                                                   "size" => 20}))
    result_json = Poison.decode!(result)
    id = result_json["id"]
    IO.puts("Created document, id: #{id}")
  end
end
