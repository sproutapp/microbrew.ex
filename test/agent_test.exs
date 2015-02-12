defmodule AgentTest do
  use Pavlov.Case, async: true
  import Pavlov.Syntax.Expect
  use Pavlov.Mocks

  import Microbrew.Agent

  describe ".new" do
    let :consumer do
      %Microbrew.Consumer{channel: nil, queue: nil}
    end

    let :sample do
      Microbrew.Agent.new(
        exchange:    "exchange",
        queue:       "queue",
        queue_error: "queue_error"
      )
    end

    before :each do
      allow(Microbrew.Agent, [:no_link, :passthrough])
        |> to_receive(consume: fn (a) -> %Microbrew.Agent{a | consumer: consumer} end)
      :ok
    end

    it "returns an %Agent with the correct properties" do
      expect sample.__struct__
        |> to_eq Microbrew.Agent

      expect sample.exchange
        |> to_eq "exchange"

      expect sample.queue
        |> to_eq "queue"

      expect sample.queue_error
        |> to_eq "queue_error"
    end

    it "creates a Consumer" do
      sample = Microbrew.Agent.new(
        exchange:    "exchange",
        queue:       "queue",
        queue_error: "queue_error"
      )

      expect sample.consumer
        |> to_eq consumer
    end
  end

  describe ".consume" do
    let :consumer do
      %Microbrew.Consumer{channel: nil, queue: nil}
    end

    let :sample do
      %Microbrew.Agent{
        exchange:    "exchange",
        queue:       "queue",
        queue_error: "queue_error"
      }
    end

    before :each do
      allow(Microbrew.Consumer)
        |> to_receive(new: fn (_, _, _) -> {:ok, consumer} end)
      :ok
    end

    it "creates a Consumer" do
      sample = sample |> consume

      expect Microbrew.Consumer
        |> to_have_received :new
        |> with ["exchange", "queue", "queue_error"]

      expect sample.consumer
        |> to_eq consumer
    end

    context "When there is already a Consumer with a non-nil channel" do
      let :a_consumer do
        %Microbrew.Consumer{channel: "channel", queue: nil}
      end

      before :each do
        allow(Microbrew.Consumer, [:no_link, :passthrough])
          |> to_receive(new: fn (_, _, _) -> {:ok, a_consumer} end)

        allow(Microbrew.Agent, [:no_link, :passthrough])
          |> to_receive(stop: fn(a) -> a end)

        :ok
      end

      it "stops the agent" do
        agent = %Microbrew.Agent{
          exchange:    "exchange",
          queue:       "queue",
          queue_error: "queue_error",
          consumer:    a_consumer
        }

        agent |> consume

        expect Microbrew.Agent
          |> to_have_received :stop
          |> with %{agent | consumer: a_consumer}
      end
    end
  end

  describe ".signal/2" do
    let :agent do
      %Microbrew.Agent{}
    end

    it "creates a signal with a given agent and event" do
      sig = agent |> signal(:data)

      expect sig.agent
        |> to_eq agent

      expect sig.event
        |> to_eq :data
    end

    it "creates a signal with a generated correlation id" do
      sig = agent |> signal(:data)

      expect sig.cid
        |> not_to_be_nil
    end
  end

  describe ".signal/3" do
    context "When the third parameter is nil" do
      let :signal do
        %Microbrew.Agent{} |> signal("my-event", nil)
      end

      it "creates a signal with a generated correlation id" do
        expect signal.cid
          |> not_to_be_nil
      end
    end

    context "When the third parameter is not nil" do
      let :signal_with_cid do
        %Microbrew.Agent{} |> signal("my-event", "my-id")
      end

      it "creates a signal with a given correlation id" do
        expect signal_with_cid.cid
          |> to_eq "my-id"
      end
    end
  end

  describe ".on" do
    context "When the event is :data" do
      before :each do
        allow(AMQP.Queue)
          |> to_receive(subscribe: fn (_, _, _) -> nil end)

        :ok
      end

      let :a_signal do
        %Microbrew.Agent{
          queue: "queue",
          consumer: %Microbrew.Consumer{channel: "channel", queue: nil},
        } |> signal("some::event")
      end
      let :callback do
        fn (_, _) -> end
      end

      it "returns the Agent" do
        agent = a_signal |> on(:data, callback)

        expect agent
          |> to_eq a_signal.agent
      end

      it "subscribes to the agent's channel and queue" do
        a_signal |> on(:data, callback)

        expect(AMQP.Queue)
          |> to_have_received :subscribe
          |> with [a_signal.agent.consumer.channel, a_signal.agent.queue, :_]
      end

      describe "Callback execution" do
        context "When \"payload[\"event\"]\" matches the subscribed event" do
          let :a_signal do
            %Microbrew.Agent{
              queue: "queue",
              consumer: %Microbrew.Consumer{channel: "channel", queue: nil},
            } |> signal("some::event")
          end

          it "fires the callback with the payload data" do
            allow(AMQP.Queue)
              |> to_receive(subscribe: fn (_, _, cb) ->
                payload = %{
                  "event" => "some::event",
                  "data"  => "some data",
                  "cid"   => "my-id"
                }
                {_, payload} = JSX.encode(payload)

                cb.(payload, nil)
              end)

            a_signal |> on(:data, fn (payload, _) ->
              expect payload["data"]
                |> to_eq "some data"
            end)
          end
        end
      end
    end
  end

  describe ".stream" do
    let :a_signal do
      %Microbrew.Agent{
        queue: "queue",
        consumer: %Microbrew.Consumer{channel: "channel", queue: nil},
      } |> signal("some::event")
    end

    let :data do
      payload = %{
        "event" => "some::event",
        "data"  => "some data",
        "cid"   => "my-id"
      }
      {_, payload} = JSX.encode(payload)
      payload
    end

    before :each do
      allow(AMQP.Basic)
        |> to_receive(get: fn (_channel, _queue) ->
          {:ok, data, []}
        end)

      :ok
    end

    it "returns a Stream of data" do
      stream = a_signal |> stream

      expect(stream |> Enum.take(4))
        |> to_eq Enum.map 1..4, fn (_) -> {data, []} end
    end
  end

  describe ".emit" do
    before :each do
      allow(Microbrew.Producer)
        |> to_receive(publish: fn (_, _) -> nil end)

      allow(Microbrew.Consumer)
        |> to_receive(new: fn (_, _, _) -> {:ok, nil} end)

      :ok
    end

    let :a_signal do
      Microbrew.Agent.new(
        exchange:    "exchange",
        queue:       "queue",
        queue_error: "queue_error"
      ) |> signal "some::event"
    end

    let :an_agent do
      a_signal.agent
    end

    let :payload do
      %{ :a_key => "some data" }
    end

    let :encoded_payload do
      p = %Microbrew.Payload{
        event: a_signal.event,
        data: payload,
        cid: a_signal.cid
      }
      {_, p} = JSX.encode p
      p
    end

    it "publishes a signal with a given payload" do
      a_signal |> emit payload

      expect(Microbrew.Producer)
        |> to_have_received :publish
        |> with [an_agent.exchange, encoded_payload]
    end
  end

  describe ".stop" do
    before :each do
      allow(Microbrew.Consumer)
        |> to_receive(close: fn (_) -> :ok end)

      :ok
    end

    let :consumer do
      %Microbrew.Consumer{channel: nil, queue: nil}
    end

    let :agent do
      %Microbrew.Agent{
        exchange:    "exchange",
        queue:       "queue",
        queue_error: "queue_error",
        consumer:    consumer
      }
    end

    it "closes the AMPQ channel" do
      agent |> stop

      expect(Microbrew.Consumer)
        |> to_have_received :close
        |> with agent.consumer
    end

    context "When the close operation returns :ok" do
      before :each do
        allow(Microbrew.Consumer)
          |> to_receive(close: fn (_) -> :ok end)

        :ok
      end

      let :consumer do
        %Microbrew.Consumer{channel: nil, queue: nil}
      end

      let :agent do
        %Microbrew.Agent{
          exchange:    "exchange",
          queue:       "queue",
          queue_error: "queue_error",
          consumer:    consumer
        }
      end

      it "returns an Agent with no Consumer" do
        a = agent |> stop

        expect(a.consumer) |> to_be_nil
      end
    end
  end
end
