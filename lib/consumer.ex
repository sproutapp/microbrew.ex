defmodule Microbrew.Consumer do
  import AMQP

  defstruct channel: nil, queue: nil
  alias __MODULE__

  def new(exchange, queue, queue_error) do
    {:ok, conn} = AMQP.Connection.open
    {:ok, chan} = AMQP.Channel.open(conn)
    AMQP.Queue.declare(chan, queue_error, durable: true)
    # Messages that cannot be delivered to any consumer in the main queue will be routed to the error queue
    AMQP.Queue.declare(chan, queue, durable: true, arguments: [
      {"x-dead-letter-exchange", :longstr, ""},
      {"x-dead-letter-routing-key", :longstr, "#{queue}_error"}
    ])
    AMQP.Exchange.topic(chan, exchange, durable: true)
    AMQP.Queue.bind(chan, queue, exchange)

    {:ok, %Consumer{channel: chan, queue: queue}}
  end
end
