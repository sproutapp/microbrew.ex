defmodule Microbrew.Signal do
  import JSX
  import AMQP
  import Microbrew.Consumer

  defstruct event: nil, consumer: nil
  alias __MODULE__

  @exchange    "sprout.sensors.readings"
  @queue       "sensor::received"
  @queue_error "#{@queue}_error"

  def new(event) do
    {:ok, consumer} = Microbrew.Consumer.new(@queue, @exchange)
    %Signal{ event: event, consumer: consumer }
  end

  def on(signal, event, callback) do
    AMQP.Queue.subscribe signal.consumer.channel, signal.consumer.queue, callback
    signal
  end

  def stop(signal) do
    AMQP.Channel.close(signal.consumer.channel)
  end
end
