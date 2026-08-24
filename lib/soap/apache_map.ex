defmodule Soap.ApacheMap do
  @moduledoc """
  Wraps a value that must be serialized as an Apache Axis `Map`
  (`http://xml.apache.org/xml-soap` by default) -- the de-facto
  convention many Java/Axis-based SOAP APIs use for a
  `java.util.Map`/`Hashtable` argument. Not a W3C/WS-I standard type,
  but a widely recognized one: Netim's `contactCreate` `additional`
  field is one such case.

  Encodes as:

      <name xsi:type="ns2:Map">
        <item>
          <key xsi:type="xsd:string">...</key>
          <value xsi:type="xsd:string">...</value>
        </item>
        ...
      </name>

  `namespace_prefix`/`namespace_uri` default to Apache Axis' own
  `ns2`/`http://xml.apache.org/xml-soap`, overridable per struct for a
  server that expects a different prefix or a variant URI for the same
  concept.
  """

  defstruct value: %{},
            namespace_prefix: "ns2",
            namespace_uri: "http://xml.apache.org/xml-soap"

  @type t() :: %__MODULE__{
          value: %{optional(String.t()) => String.t()},
          namespace_prefix: String.t(),
          namespace_uri: String.t()
        }
end

defimpl Soap.Argument, for: Soap.ApacheMap do
  alias Proximal.Xmlel

  def to_xmlel(%Soap.ApacheMap{value: map, namespace_prefix: prefix}, name) do
    items =
      Enum.map(map, fn {key, value} ->
        Xmlel.new("item", %{}, [
          Xmlel.new("key", %{"xsi:type" => "xsd:string"}, [to_string(key)]),
          Xmlel.new("value", %{"xsi:type" => "xsd:string"}, [to_string(value)])
        ])
      end)

    Xmlel.new(name, %{"xsi:type" => "#{prefix}:Map"}, items)
  end

  def namespaces(%Soap.ApacheMap{namespace_prefix: prefix, namespace_uri: uri}) do
    %{prefix => uri}
  end
end
