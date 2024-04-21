defmodule Soap.Decode do
  @moduledoc """
  Decode a SOAP response from a server. It's performing the conversion of the
  response and applying types.
  """
  require Logger
  alias Proximal.Xmlel

  @doc """
  Decode the response for a SOAP call. It's returning the data in a
  map form.
  """
  @spec decode(envelope :: String.t()) :: map()
  def decode(envelope) when is_binary(envelope) do
    Logger.debug("envelope: #{envelope}")
    [%Xmlel{children: [response]}] = Proximal.to_xmlel(envelope)["Body"]
    Map.new(response.children, &to_map/1)
  end

  defp convert_data({:type, :string}, data), do: data

  defp convert_data({:type, :boolean}, data) do
    case String.downcase(data) do
      "true" -> true
      "false" -> false
      "1" -> true
      "0" -> false
    end
  end

  defp convert_data({:type, :integer}, data), do: String.to_integer(data)

  defp convert_data({:type, :float}, data) do
    if String.contains?(data, ".") do
      String.to_float(data)
    else
      String.to_float(data <> ".0")
    end
  end

  defp convert_data({:type, :decimal}, data), do: Decimal.new(data)

  defp convert_data({:type, :uri}, data), do: URI.parse(data)

  defp convert_data({:type, :datetime}, data) do
    {:ok, datetime, _offset} = DateTime.from_iso8601(data)
    datetime
  end

  defp convert_data(attr_type, data), do: convert_data({:type, get_type(attr_type)}, data)

  defguardp item?(name)
            when binary_part(name, 0, 1) in ~w[ i I ] and
                   binary_part(name, 1, 1) in ~w[ t T ] and
                   binary_part(name, 2, 1) in ~w[ e E ] and
                   binary_part(name, 3, 1) in ~w[ m M ]

  defp to_map(%Xmlel{name: name, children: [data]} = xmlel)
       when is_binary(data) and item?(name) do
    convert_data(Xmlel.get_attr(xmlel, "type", "string"), data)
  end

  defp to_map(%Xmlel{name: name, children: children}) when item?(name) do
    values = Enum.map(children, &to_map/1)

    if Enum.all?(values, &is_tuple/1) do
      Map.new(values)
    else
      values
    end
  end

  defp to_map(%Xmlel{name: name, children: [data]} = xmlel) when is_binary(data) do
    {name, convert_data(Xmlel.get_attr(xmlel, "type", "string"), data)}
  end

  defp to_map(%Xmlel{name: name, children: []} = xmlel) do
    case {Xmlel.get_attr(xmlel, "nil"), get_type(Xmlel.get_attr(xmlel, "type"))} do
      {"true", _} -> {name, nil}
      {_, nil} -> {name, nil}
      {_, :string} -> {name, ""}
      {_, :boolean} -> {name, false}
      {_, :integer} -> {name, 0}
      {_, :map} -> {name, %{}}
      {_, :array} -> {name, []}
    end
  end

  defp to_map(%Xmlel{name: name, children: children}) do
    values = Enum.map(children, &to_map/1)

    if Enum.all?(values, &is_tuple/1) do
      {name, Map.new(values)}
    else
      {name, values}
    end
  end

  defp get_type(nil), do: nil
  defp get_type("string"), do: :string
  defp get_type("int"), do: :integer
  defp get_type("integer"), do: :integer
  defp get_type("float"), do: :float
  defp get_type("double"), do: :float
  defp get_type("decimal"), do: :decimal
  defp get_type("anyURI"), do: :uri
  defp get_type("dateTime"), do: :datetime
  defp get_type("boolean"), do: :boolean
  defp get_type("XMLLiteral"), do: :xml_literal
  defp get_type("Map"), do: :map
  defp get_type("ArrayOfString"), do: :array

  defp get_type(complex) do
    case String.split(complex, ":", parts: 2) do
      [_ns, type] ->
        get_type(type)

      [_type] ->
        # TODO handle custom types
        :array
    end
  end
end
