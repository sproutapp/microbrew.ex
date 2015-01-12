defmodule Microbrew.Agent do
  import JSX
  import AMQP
  import Microbrew.Consumer

  defstruct exchange: nil, queue: nil, queue_error: nil, consumer: nil
  alias __MODULE__

  defmodule Signal do
    defstruct agent: nil, event: nil
  end

  def new(options \\ []) do
    exchange = Keyword.get(options, :exchange, "")
    queue = Keyword.get(options, :queue, "")
    queue_error = Keyword.get(options, :queue_error, nil)

    agent = %Agent{
      exchange: exchange,
      queue: queue,
      queue_error: queue_error,
    }

    __MODULE__.consume(agent)
  end

  def consume(agent) do
    {:ok, consumer} = Microbrew.Consumer.new(agent.exchange, agent.queue, agent.queue_error)
    %{agent | consumer: consumer}
  end

  def signal(agent, event) do
    %Signal{agent: agent, event: event}
  end

  def on(signal, :data, callback) when is_function(callback, 2) do
    channel = signal.agent.consumer.channel
    queue = signal.agent.queue

    AMQP.Queue.subscribe channel, queue, fn (payload, meta) ->
      {_, payload} = JSX.decode(payload)

      if payload["event"] == signal.event do
        callback.(payload, meta)
      end
    end

    signal.agent
  end

  def stop(signal) do
    AMQP.Channel.close(signal.consumer.channel)
  end
end
