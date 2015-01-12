defmodule Fixtures.Mock do
  alias Fixtures.Mock, as: Mock
  @moduledoc false
  @doc false
  def on_callback(payload) do
    payload
  end
end
