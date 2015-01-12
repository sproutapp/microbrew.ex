# Microbrew
A Microservices Toolkit

## Agent
Not to be mistaken with an Elixir.Agent, a Microbrew `Agent` is an entity that
can be used to receive and emit signals.

You can create an agent using the `new` method:

```elixir
Microbrew.Agent.new(
  exchange:    "an_exchange",
  queue:       "a_queue",
  queue_error: "an_error_queue"
)
# => %Microbrew.Agent{exchange: "an_exchange", queue: "a_queue", queue_error: "an_error_queue"}
```

Using `new` automatically configures your `Agent` with Consumer and Producer
capabilities.

## Consume
Instead of using `Microbrew.Agent.new`, you can create the struct yourself and
use the composable `consume` method:

```elixir
agent = %Microbrew.Agent{
  exchange: "an_exchange",
  queue: "a_queue",
  queue_error: "an_error_queue",
}

agent |> consume |> ...
```

## Signal
A signal models an event in the system. It is mainly used to compose into the
`on` and `emit` methods.

```elixir
agent |> signal "temperature::new"
# => %Signal{agent: agent, event: "temperature::new"}
```

## on
Sets up a consumer for a given `Signal`. Currently the only consumer supported
is `:data`. It is triggered whenever any kind of data payload that matches your
`Signal` comes in through the wire. Payloads are decoded from JSON into `Map`s.

```elixir
agent
 |> signal "temperature::new"
 |> on :data, fn (payload, meta) ->
   # Do something with "payload" and "meta"
 end
```

## emit
Publishes a payload under a given `Signal`. Payloads are published in
JSON format.

```elixir
signal "temperature::new"
  |> emit "hello world"
# => {:ok}
```
