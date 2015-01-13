defmodule Microbrew do

  defmodule Config do
    def config(name) do
      Application.get_env(:microbrew, name)
    end

    def rabbitmq_url do
      rabbitmq = config(:rabbitmq)
      "amqp://#{rabbitmq[:username]}:#{rabbitmq[:password]}@#{rabbitmq[:host]}"
    end
  end
end
