# Microbrew
A Microservices Toolkit. Provides a simple, composable framework for exchanging messages in a distributed system. Currently supports AMQP message brokers, but it has only been tested with RabbitMQ so far.

# Configuration
Microbrew uses configuration specified in your `config.exs` file to connect to a
RabbitMQ instance. The default configuration is:

```elixir
config :microbrew, :rabbitmq,
  username: "guest",
  password: "guest",
  host: "localhost",
  port: 5672
```

## Agents
Agents are at the core of Microbrew.
Not to be mistaken with an `Elixir.Agent`, a `Microbrew.Agent` is an entity that
can be used to receive and emit signals in a distributed system.

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
capabilities. While producing content has no continuous overhead, a constant
connection is required to consume content, so you may wish not to use `.new` and
instead create the struct yourself.

```elixir
agent = %Microbrew.Agent{
  exchange: "an_exchange",
  queue: "a_queue",
  queue_error: "an_error_queue",
}
```

### .consume
If you already have an agent created without Consumer capabilities, you can
add them by calling `consume`:

```elixir
agent = %Microbrew.Agent{
  exchange: "an_exchange",
  queue: "a_queue",
  queue_error: "an_error_queue",
}

agent |> consume |> ...
```

### .signal
A signal models an event in the system. It is mainly used to compose into the
`on` and `emit` methods.

```elixir
agent |> signal "temperature::new"
# => %Signal{agent: agent, event: "temperature::new"}
```

### .on
Sets up a consumer for a given `Signal`. Currently the only consumer supported
is `:data`. It is triggered whenever any kind of data payload that matches your
`Signal` comes in through the wire. Payloads are decoded from JSON into `Maps`.

```elixir
agent
 |> signal "temperature::new"
 |> on :data, fn (payload, meta) ->
   # Do something with "payload" and "meta"
 end
```

### .stream
Lets you access `Signal` data as a Stream. Each value in the stream is a tuple
containing the `payload` and `meta` information.

```elixir
agent
  |> signal("sensor::received")
  |> stream
# #Function<25.29647706/2 in Stream.resource/3>
```

### .emit
Publishes a payload under a given `Signal`. Payloads are published in
JSON format.

```elixir
signal "temperature::new"
  |> emit "hello world"
# => {:ok}
```

### .stop
Stops an `Agent`. This effectively shuts down any `Consumer` behaviour for the
given `Agent`. You can still publish, though. To restart `Consumer` behaviour use
`.consume`.

```elixir
agent |> stop
# => :ok
```
