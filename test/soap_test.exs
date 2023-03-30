defmodule SoapTest do
  use ExUnit.Case
  import Proximal.Xmlel, only: [sigil_x: 2]

  describe "encoding" do
    test "simple new" do
      assert %Soap{method: "domainInfo"} == Soap.new("domainInfo")
    end

    test "change encoding style" do
      old_soap = Soap.new("domainInfo")
      new_soap = Soap.set_encoding_style(old_soap, "urn:new-encoding")
      assert %Soap{encoding_style: "urn:new-encoding"} = new_soap
      assert new_soap.encoding_style != old_soap.encoding_style
    end

    test "put a new namespace" do
      soap =
        Soap.new("getInfo")
        |> Soap.put_namespace("xsd", "http://www.w3.org/2001/XMLSchema/")

      assert ~x|<soap-env:Envelope xmlns:soap-enc="http://schemas.xmlsoap.org/soap/encoding/"
                                   xmlns:soap-env="http://schemas.xmlsoap.org/soap/envelope/"
                                   xmlns:xsd="http://www.w3.org/2001/XMLSchema/"
                                   soap-env:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">
                  <soap-env:Body>
                    <getInfo/>
                  </soap-env:Body>
                </soap-env:Envelope>| == Proximal.to_xmlel(soap)
    end

    test "new with named parameters" do
      soap =
        Soap.new("domainInfo", [{"IDSession", "1234abc"}, {"domain", "altenwald.com"}], "urn:DRS")

      assert ~x|<soap-env:Envelope xmlns:m="urn:DRS"
                                   xmlns:soap-enc="http://schemas.xmlsoap.org/soap/encoding/"
                                   xmlns:soap-env="http://schemas.xmlsoap.org/soap/envelope/"
                                   soap-env:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">
                    <soap-env:Body>
                      <m:domainInfo>
                        <IDSession>1234abc</IDSession>
                        <domain>altenwald.com</domain>
                      </m:domainInfo>
                    </soap-env:Body>
                  </soap-env:Envelope>| == Proximal.to_xmlel(soap)
    end

    test "new with unnamed parameters" do
      soap = Soap.new("domainInfo", ["1234abc", "altenwald.com"], "urn:DRS")

      assert ~x|<soap-env:Envelope xmlns:m="urn:DRS"
                                   xmlns:soap-enc="http://schemas.xmlsoap.org/soap/encoding/"
                                   xmlns:soap-env="http://schemas.xmlsoap.org/soap/envelope/"
                                   soap-env:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">
                    <soap-env:Body>
                      <m:domainInfo>
                        <Item>1234abc</Item>
                        <Item>altenwald.com</Item>
                      </m:domainInfo>
                    </soap-env:Body>
                  </soap-env:Envelope>| == Proximal.to_xmlel(soap)
    end

    test "new with named and nested parameters" do
      soap = Soap.new("contactInfo", ["1234abc", {"contact", [{"firstName", "Manuel"}, {"lastName", "Rubio"}]}], "urn:DRS")

      assert ~x|<soap-env:Envelope xmlns:m="urn:DRS"
                                   xmlns:soap-enc="http://schemas.xmlsoap.org/soap/encoding/"
                                   xmlns:soap-env="http://schemas.xmlsoap.org/soap/envelope/"
                                   soap-env:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">
                    <soap-env:Body>
                      <m:contactInfo>
                        <Item>1234abc</Item>
                        <contact>
                          <firstName>Manuel</firstName>
                          <lastName>Rubio</lastName>
                        </contact>
                      </m:contactInfo>
                    </soap-env:Body>
                  </soap-env:Envelope>| == Proximal.to_xmlel(soap)
    end
  end
end
