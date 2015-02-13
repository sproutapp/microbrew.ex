defmodule Microbrew.Consumer do
  import AMQP

  defstruct channel: nil, queue: nil
  alias __MODULE__

  def new(exchange, queue, queue_error, options \\ []) do
    {:ok, conn} = AMQP.Connection.open Microbrew.Config.rabbitmq_url
    {:ok, chan} = AMQP.Channel.open(conn)
    AMQP.Queue.declare(chan, queue_error, durable: true)
    # Messages that cannot be delivered to any consumer in the main queue will be routed to the error queue
    AMQP.Queue.declare(chan, queue, durable: true, arguments: [
      {"x-dead-letter-exchange", :longstr, ""},
      {"x-dead-letter-routing-key", :longstr, queue_error}
    ])

    AMQP.Queue.bind chan, queue, start_exchange({chan, exchange}, options)

    {:ok, %Consumer{channel: chan, queue: queue}}
  end

  def close(consumer) do
    AMQP.Channel.close(consumer.channel)
  end

  defp start_exchange({channel, exchange}, options) do
    options = Keyword.merge exchange_defaults, Keyword.get(options, :exchange, [])

    case options[:type] do
      :fanout -> &AMQP.Exchange.fanout/3
      :topic  -> &AMQP.Exchange.topic/3
      _       -> &AMQP.Exchange.direct/3
    end
    |> apply [channel, exchange, [durable: options[:durable]]]

    exchange
  end

  defp exchange_defaults do
    [
      type: :direct,
      durable: true
    ]
  end
end
