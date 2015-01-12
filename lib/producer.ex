defmodule Microbrew.Producer do
  import AMQP

  def publish(exchange, payload) do
    {:ok, conn} = AMQP.Connection.open("amqp://guest:guest@localhost")
    {:ok, chan} = AMQP.Channel.open(conn)

    AMQP.Basic.publish chan, exchange, "", payload
    AMQP.Connection.close(conn)
  end
end
