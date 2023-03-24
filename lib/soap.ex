defmodule Soap do
  @moduledoc """
  SOAP data structure letting us to create a function for performing a call.
  See `new/1`, `new/2`, and `new/3` for further details.
  """
  defstruct namespaces: %{},
            encoding_style: "http://schemas.xmlsoap.org/soap/encoding/",
            method_namespace: nil,
            method: nil,
            arguments: []

  def new(method, arguments \\ [], namespace \\ nil) do
    %__MODULE__{method: method, arguments: arguments, method_namespace: namespace}
  end

  def set_encoding_style(soap, encoding_style) when is_binary(encoding_style) do
    %__MODULE__{soap | encoding_style: encoding_style}
  end

  def put_namespace(soap, name, uri) do
    %__MODULE__{soap | namespaces: Map.put(soap.namespaces, name, uri)}
  end

  defimpl Proximal, for: __MODULE__ do
    alias Proximal.Xmlel

    def to_xmlel(%Soap{} = soap) do
      default_ns = %{
        "soap-env" => "http://schemas.xmlsoap.org/soap/envelope/",
        "soap-enc" => "http://schemas.xmlsoap.org/soap/encoding/"
      }

      namespaces = Map.merge(default_ns, soap.namespaces)
      arguments = arguments_to_xmlel(soap.arguments)

      attrs =
        namespaces
        |> Map.new(fn {ns, uri} -> {"xmlns:#{ns}", uri} end)
        |> Map.put("soap-env:encodingStyle", soap.encoding_style)

      if ns = soap.method_namespace do
        Xmlel.new("soap-env:Envelope", Map.put(attrs, "xmlns:m", ns), [
          Xmlel.new("soap-env:Body", %{}, [
            Xmlel.new("m:#{soap.method}", %{}, arguments)
          ])
        ])
      else
        Xmlel.new("soap-env:Envelope", attrs, [
          Xmlel.new("soap-env:Body", %{}, [
            Xmlel.new(soap.method, %{}, arguments)
          ])
        ])
      end
    end

    defp arguments_to_xmlel([]), do: []

    defp arguments_to_xmlel([{name, value} | rest]) do
      [Xmlel.new(name, %{}, [to_string(value)]) | arguments_to_xmlel(rest)]
    end

    defp arguments_to_xmlel([value | rest]) when not is_map(value) and not is_list(value) do
      [Xmlel.new("Item", %{}, [to_string(value)]) | arguments_to_xmlel(rest)]
    end
  end
end
