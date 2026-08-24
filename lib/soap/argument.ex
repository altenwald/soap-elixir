defprotocol Soap.Argument do
  @moduledoc """
  Protocol for encoding a value with no native SOAP representation into
  its `Proximal.Xmlel` argument element.

  Most argument values (strings, numbers, lists, nested `{name, value}`
  tuples...) already have a natural encoding built into `Soap` itself.
  This protocol exists for the rest -- types a particular SOAP API
  expects in a shape of its own, like Apache Axis' `ns2:Map` (see
  `Soap.ApacheMap`). Implement it for your own struct to teach `Soap`
  how to encode it, without ever having to modify this library.

  Anything without an implementation falls back to the default
  `to_string/1`-based encoding (`xsi:type="xsd:string"`), so adding this
  protocol never breaks a struct that used to rely on that fallback.
  """
  @fallback_to_any true

  @doc """
  Encodes `value` as the argument element named `name`.
  """
  @spec to_xmlel(t(), Soap.argument_name()) :: Proximal.Xmlel.t()
  def to_xmlel(value, name)

  @doc """
  Extra `xmlns:` namespaces (as a `%{name => uri}` map) that must be
  declared on the SOAP envelope for `to_xmlel/2`'s output to be valid --
  e.g. `Soap.ApacheMap` needs its `ns2` prefix declared. Return `%{}`
  when the encoding needs nothing beyond the envelope's own defaults.
  """
  @spec namespaces(t()) :: %{Soap.namespace_name() => Soap.namespace_uri()}
  def namespaces(value)
end

defimpl Soap.Argument, for: Any do
  alias Proximal.Xmlel

  def to_xmlel(value, name) do
    Xmlel.new(name, %{"xsi:type" => "xsd:string"}, [to_string(value)])
  end

  def namespaces(_value), do: %{}
end
