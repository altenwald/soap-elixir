defmodule Soap.ArgumentTest do
  use ExUnit.Case
  import Proximal.Xmlel, only: [sigil_x: 2]

  # A third-party-ish struct, defined here (not in lib/), implementing
  # Soap.Argument entirely from the outside -- this is the point of the
  # protocol: a consumer can teach `Soap` how to encode its own special
  # types without ever touching this library's source.
  defmodule Vector do
    defstruct items: []
  end

  defimpl Soap.Argument, for: Vector do
    alias Proximal.Xmlel

    def to_xmlel(%Vector{items: items}, name) do
      children =
        Enum.map(items, fn item ->
          Xmlel.new("item", %{"xsi:type" => "xsd:string"}, [to_string(item)])
        end)

      Xmlel.new(name, %{"xsi:type" => "vec:Vector"}, children)
    end

    # Declaring a namespace here too, not just in ApacheMap's implementation,
    # proves Soap collects it from *any* Soap.Argument impl generically --
    # not something hardcoded for the Apache Map case.
    def namespaces(_value), do: %{"vec" => "urn:test-vector"}
  end

  test "a struct implementing Soap.Argument encodes itself and declares its own namespace" do
    soap = Soap.new("op", [{"list", %Vector{items: ["a", "b"]}}], "urn:DRS")

    assert ~x|<soap-env:Envelope xmlns:m="urn:DRS"
                                 xmlns:vec="urn:test-vector"
                                 xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                                 xmlns:xsd="http://www.w3.org/2001/XMLSchema"
                                 xmlns:soap-enc="http://schemas.xmlsoap.org/soap/encoding/"
                                 xmlns:soap-env="http://schemas.xmlsoap.org/soap/envelope/"
                                 soap-env:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">
                  <soap-env:Body>
                    <m:op>
                      <list xsi:type="vec:Vector">
                        <item xsi:type="xsd:string">a</item>
                        <item xsi:type="xsd:string">b</item>
                      </list>
                    </m:op>
                  </soap-env:Body>
                </soap-env:Envelope>| == Proximal.to_xmlel(soap)
  end

  defmodule Plain do
    defstruct [:x]
  end

  defimpl String.Chars, for: Plain do
    def to_string(%Plain{x: x}), do: "plain-#{x}"
  end

  test "a struct with no Soap.Argument implementation falls back to xsd:string" do
    soap = Soap.new("op", [{"thing", %Plain{x: 1}}], "urn:DRS")

    assert ~x|<soap-env:Envelope xmlns:m="urn:DRS"
                                 xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                                 xmlns:xsd="http://www.w3.org/2001/XMLSchema"
                                 xmlns:soap-enc="http://schemas.xmlsoap.org/soap/encoding/"
                                 xmlns:soap-env="http://schemas.xmlsoap.org/soap/envelope/"
                                 soap-env:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">
                  <soap-env:Body>
                    <m:op>
                      <thing xsi:type="xsd:string">plain-1</thing>
                    </m:op>
                  </soap-env:Body>
                </soap-env:Envelope>| == Proximal.to_xmlel(soap)
  end
end
