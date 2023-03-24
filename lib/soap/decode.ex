defmodule Soap.Decode do
  require Logger
  alias Proximal.Xmlel

  def decode(envelope) when is_binary(envelope) do
    Logger.debug("envelope: #{envelope}")
    [%Xmlel{children: [response]}] = Proximal.to_xmlel(envelope)["Body"]
    Map.new(response.children, &to_map/1)
  end

  defp convert_data(attr_type, data) do
    case get_type(attr_type) do
      :string -> data
      :boolean ->
        case String.downcase(data) do
          "true" -> true
          "false" -> false
          "1" -> true
          "0" -> false
        end
      :integer -> String.to_integer(data)
      :float -> String.to_float(data)
      :decimal -> Decimal.new(data)
      :uri -> URI.parse(data)
      :datetime ->
        {:ok, datetime, _offset} = DateTime.from_iso8601(data)
        datetime
    end
  end

  defp to_map(%Xmlel{name: "item", children: [data]} = xmlel) when is_binary(data) do
    convert_data(Xmlel.get_attr(xmlel, "type", "string"), data)
  end

  defp to_map(%Xmlel{name: "item", children: children}), do: Enum.map(children, &to_map/1)

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
  defp get_type(complex) do
    [_ns, type] = String.split(complex, ":", parts: 2)
    get_type(type)
  end
end
