defmodule SignalTest do
  use Pavlov.Case, async: true
  import Pavlov.Syntax.Expect
  use Pavlov.Mocks

  import Microbrew.Signal
  import Fixtures.Mock

  describe ".new" do
    let :sample do
      Microbrew.Signal.new("temperature::new")
    end

    it "returns a %Signal" do
      expect sample.__struct__
        |> to_eq Microbrew.Signal
    end
  end

  xdescribe ".on" do
  end
end
