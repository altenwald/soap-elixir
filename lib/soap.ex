defmodule Soap do
  @moduledoc """
  SOAP data structure letting us to create a function for performing a call.
  See `new/1`, `new/2`, and `new/3` for further details.
  """

  @typedoc """
  The information required to create the XML representation for a SOAP remote
  call. It's composed of:

  - `namespaces` a map containing the handler as key and the URL for the
    namespace as the value.
  - `encoding_style` is the style for encoding the SOAP message.
  - `method_namespace` is the namespace for the current call.
  - `method` is the method name.
  - `soap_action` is the SOAPAction header.
  - `arguments` is the list of arguments to be encoded to be sent
    as part of the SOAP call.
  """
  @type t() :: %__MODULE__{
          namespaces: %{namespace_name() => namespace_uri()},
          encoding_style: namespace_uri(),
          method_namespace: namespace_name() | nil,
          method: method_name() | nil,
          soap_action: soap_action() | nil,
          arguments: [argument()]
        }

  @type namespace_name() :: String.t()
  @type namespace_uri() :: String.t()
  @type method_name() :: String.t()
  @type soap_action() :: String.t()
  @type argument_name() :: String.t()
  @type argument() ::
          String.t() | number() | boolean() | {argument_name(), argument() | [argument()]}

  defstruct namespaces: %{},
            encoding_style: "http://schemas.xmlsoap.org/soap/encoding/",
            method_namespace: nil,
            method: nil,
            soap_action: nil,
            arguments: []

  @doc """
  Creates a new SOAP call method. It's creating the structure that we could
  use to generate a XML SOAP call.
  """
  @spec new(method_name(), [argument()], namespace_uri() | nil) :: t()
  def new(method_name, arguments \\ [], namespace_uri \\ nil) do
    %__MODULE__{method: method_name, arguments: arguments, method_namespace: namespace_uri}
  end

  @doc """
  Change the encoding style. Note that at the moment we cannot use a different
  encoding style than `http://schemas.xmlsoap.org/soap/encoding/`.
  """
  def set_encoding_style(soap, encoding_style) when is_binary(encoding_style) do
    %__MODULE__{soap | encoding_style: encoding_style}
  end

  @doc """
  Set the SOAPAction header. Note that this is an optional data and it's not
  compulsory to be filled.
  """
  def set_soap_action(soap, soap_action) when is_binary(soap_action) do
    %__MODULE__{soap | soap_action: soap_action}
  end

  @doc """
  It's adding a new namespace given the name and the URI to be added to the
  namespaces map.
  """
  def put_namespace(soap, name, uri) do
    %__MODULE__{soap | namespaces: Map.put(soap.namespaces, name, uri)}
  end

  defimpl Proximal, for: __MODULE__ do
    alias Proximal.Xmlel

    def to_xmlel(%Soap{} = soap) do
      default_ns = %{
        "soap-env" => "http://schemas.xmlsoap.org/soap/envelope/",
        "soap-enc" => "http://schemas.xmlsoap.org/soap/encoding/",
        "xsi" => "http://www.w3.org/2001/XMLSchema-instance",
        "xsd" => "http://www.w3.org/2001/XMLSchema"
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

    defp arguments_to_xmlel([{name, value} | rest]) when is_list(value) do
      [Xmlel.new(name, %{}, arguments_to_xmlel(value)) | arguments_to_xmlel(rest)]
    end

    defp arguments_to_xmlel([{name, value} | rest]) when is_integer(value) do
      [Xmlel.new(name, %{"xsi:type" => "xsd:int"}, [to_string(value)]) | arguments_to_xmlel(rest)]
    end

    defp arguments_to_xmlel([{name, value} | rest]) do
      [
        Xmlel.new(name, %{"xsi:type" => "xsd:string"}, [to_string(value)])
        | arguments_to_xmlel(rest)
      ]
    end

    defp arguments_to_xmlel([value | rest]) when is_integer(value) do
      [
        Xmlel.new("Item", %{"xsi:type" => "xsd:int"}, [to_string(value)])
        | arguments_to_xmlel(rest)
      ]
    end

    defp arguments_to_xmlel([value | rest]) when not is_map(value) and not is_list(value) do
      [
        Xmlel.new("Item", %{"xsi:type" => "xsd:string"}, [to_string(value)])
        | arguments_to_xmlel(rest)
      ]
    end

    defp arguments_to_xmlel([values | rest]) when is_list(values) do
      [Xmlel.new("Item", %{}, arguments_to_xmlel(values)) | arguments_to_xmlel(rest)]
    end
  end
end
