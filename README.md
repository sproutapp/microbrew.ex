# Microbrew
A Microservices Toolkit

## signal
An event in the system. Can be composed with `on` and `emit`.

```elixir
signal "temperature::new"
# => %Signal{event: "temperature::new"}
```

## on
Sets up a consumer for a given `Signal` and `event` name.

```elixir
signal "temperature::new"
  |> on :data, fn (payload) ->
    # Do something with "payload"
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
