defmodule Soap.Client do
  @moduledoc """
  Let us perform a HTTP request to a SOAP server. If everything goes well
  we will get the correct response and this will be decoded as a map.
  """
  require Logger

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
    resp_head = {'HTTP/1.1', 200, 'OK'}

    with {:ok, {^resp_head, _headers, resp_body}} <-
           :httpc.request(:post, request, http_opts, opts),
         %{} = response <- Soap.Decode.decode(to_string(resp_body)) do
      {:ok, response}
    end
  end
end
