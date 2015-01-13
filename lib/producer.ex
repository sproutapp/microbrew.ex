defmodule Microbrew.Producer do
  import AMQP

  def publish(exchange, payload) do
    {:ok, conn} = AMQP.Connection.open Microbrew.Config.rabbitmq_url
    {:ok, chan} = AMQP.Channel.open(conn)

    AMQP.Basic.publish chan, exchange, "", payload
    AMQP.Connection.close(conn)
  end
end
