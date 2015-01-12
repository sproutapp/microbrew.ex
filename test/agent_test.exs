defmodule SignalTest do
  use Pavlov.Case, async: true
  import Pavlov.Syntax.Expect
  use Pavlov.Mocks

  import Microbrew.Agent

  describe ".new" do
    let :exchange do
      "exchange"
    end
    let :queue do
      "queue"
    end
    let :queue_error do
      "queue_error"
    end

    let :sample do
      Microbrew.Agent.new(
        exchange:    exchange,
        queue:       queue,
        queue_error: queue_error
      )
    end

    let :consumer do
      %Microbrew.Consumer{channel: nil, queue: nil}
    end

    before :each do
      allow(Microbrew.Consumer)
        |> to_receive(new: fn (_, _, _) -> {:ok, consumer} end)
      :ok
    end

    it "returns an %Agent with the correct properties" do
      expect sample.__struct__
        |> to_eq Microbrew.Agent

      expect sample.exchange
        |> to_eq exchange

      expect sample.queue
        |> to_eq queue

      expect sample.queue_error
        |> to_eq queue_error
    end

    it "creates a Consumer" do
      agent = Microbrew.Agent.new(
        exchange:    exchange,
        queue:       queue,
        queue_error: queue_error
      )

      expect Microbrew.Consumer
        |> to_have_received :new
        |> with [exchange, queue, queue_error]

      expect agent.consumer
        |> to_eq consumer
    end
  end

  describe ".signal" do
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

          it "fires the callback with the payload" do
            allow(AMQP.Queue)
              |> to_receive(subscribe: fn (_, _, cb) ->
                payload = %{
                  "event" => "some::event",
                  "data"  => "some data"
                }
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
end
