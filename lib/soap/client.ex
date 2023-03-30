defmodule Soap.Client do
  @moduledoc """
  Let us perform a HTTP request to a SOAP server. If everything goes well
  we will get the correct response and this will be decoded as a map.
  """
  require Logger

  @doc """
  Performs an external request using the SOAP structure passed as parameter
  to the URL (in the first parameter).
  """
  @spec request(url :: String.t(), Soap.t()) :: {:ok, map()} | {:error, any()}
  def request(url, %Soap{} = soap) when is_binary(url) do
    url = to_charlist(url)
    req_headers = []
    content_type = 'text/xml'
    http_opts = []
    opts = []

    req_body =
      soap
      |> Proximal.to_xmlel()
      |> to_string()

    Logger.debug("request: #{req_body}")
    request = {url, req_headers, content_type, req_body}

    with {:ok, {{'HTTP/' ++ _, 200, 'OK'}, _headers, resp_body}} <-
           :httpc.request(:post, request, http_opts, opts),
         %{} = response <- Soap.Decode.decode(to_string(resp_body)) do
      {:ok, response}
    else
      {:ok, {{'HTTP/' ++ _, 500, _error}, _headers, resp_body}} ->
        {:error, Soap.Decode.decode(to_string(resp_body))}
    end
  end
end
