defmodule Microbrew.Agent do
  defstruct exchange: nil, queue: nil, queue_error: nil, consumer: nil
  alias __MODULE__

  require IEx

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
    if agent.consumer != nil && agent.consumer.channel != nil do
      agent = Microbrew.Agent.stop agent
    end

    {:ok, consumer} = Microbrew.Consumer.new(agent.exchange, agent.queue, agent.queue_error)
    %{agent | consumer: consumer}
  end

  def signal(agent, event, cid) do
    cid = if cid != nil, do: cid, else: UUID.uuid4()
    %Signal{agent: agent, event: event, cid: cid}
  end
  def signal(agent, event) do
    signal(agent, event, nil)
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

  def stream(signal, evt \\ :data) do
    Stream.resource(
      fn -> signal end,
      fn signal ->
        channel = signal.agent.consumer.channel
        queue = signal.agent.queue

        case AMQP.Basic.get channel, queue do
          {:ok, payload, meta} -> { [{payload, meta}], signal}
          {:empty, _meta} -> {:halt, signal}
        end
      end,
      fn signal -> signal end
    )
    |> Stream.map(fn {value, meta} ->
      {_, payload} = JSX.decode value
      {payload, meta}
    end)
    |> Stream.reject(fn {value, _meta} ->
      value["event"] != signal.event
    end)
  end

  def emit(signal, payload) do
    payload = %Microbrew.Payload{
      event: signal.event,
      data: payload,
      cid: signal.cid
    }
    {_, payload} = JSX.encode(payload)

    agent = signal.agent

    Microbrew.Producer.publish(agent.exchange, payload)
  end

  def stop(agent) do
    case Microbrew.Consumer.close(agent.consumer) do
      :ok -> %{agent | consumer: nil}
    end
  end
end
