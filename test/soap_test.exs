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
        |> Soap.put_namespace("custom", "urn:custom")

      assert ~x|<soap-env:Envelope xmlns:soap-enc="http://schemas.xmlsoap.org/soap/encoding/"
                                   xmlns:xsd="http://www.w3.org/2001/XMLSchema"
                                   xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                                   xmlns:soap-env="http://schemas.xmlsoap.org/soap/envelope/"
                                   xmlns:custom="urn:custom"
                                   soap-env:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">
                  <soap-env:Body>
                    <getInfo/>
                  </soap-env:Body>
                </soap-env:Envelope>| == Proximal.to_xmlel(soap)
    end

    test "new with named parameters" do
      soap = Soap.new("domainInfo", [{"id", 1234}, {"price", 0.0}, {"domain", "altenwald.com"}], "urn:DRS")

      assert ~x|<soap-env:Envelope xmlns:m="urn:DRS"
                                   xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                                   xmlns:xsd="http://www.w3.org/2001/XMLSchema"
                                   xmlns:soap-enc="http://schemas.xmlsoap.org/soap/encoding/"
                                   xmlns:soap-env="http://schemas.xmlsoap.org/soap/envelope/"
                                   soap-env:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">
                    <soap-env:Body>
                      <m:domainInfo>
                        <id xsi:type="xsd:int">1234</id>
                        <price xsi:type="xsd:double">0.0</price>
                        <domain xsi:type="xsd:string">altenwald.com</domain>
                      </m:domainInfo>
                    </soap-env:Body>
                  </soap-env:Envelope>| == Proximal.to_xmlel(soap)
    end

    test "new with unnamed parameters" do
      soap = Soap.new("domainInfo", ["1234abc", "altenwald.com"], "urn:DRS")

      assert ~x|<soap-env:Envelope xmlns:m="urn:DRS"
                                   xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                                   xmlns:xsd="http://www.w3.org/2001/XMLSchema"
                                   xmlns:soap-enc="http://schemas.xmlsoap.org/soap/encoding/"
                                   xmlns:soap-env="http://schemas.xmlsoap.org/soap/envelope/"
                                   soap-env:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">
                    <soap-env:Body>
                      <m:domainInfo>
                        <Item xsi:type="xsd:string">1234abc</Item>
                        <Item xsi:type="xsd:string">altenwald.com</Item>
                      </m:domainInfo>
                    </soap-env:Body>
                  </soap-env:Envelope>| == Proximal.to_xmlel(soap)
    end

    test "new with named and nested parameters" do
      soap =
        Soap.new(
          "contactInfo",
          ["1234abc", {"contact", [{"firstName", "Manuel"}, {"lastName", "Rubio"}]}],
          "urn:DRS"
        )

      assert ~x|<soap-env:Envelope xmlns:m="urn:DRS"
                                   xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                                   xmlns:xsd="http://www.w3.org/2001/XMLSchema"
                                   xmlns:soap-enc="http://schemas.xmlsoap.org/soap/encoding/"
                                   xmlns:soap-env="http://schemas.xmlsoap.org/soap/envelope/"
                                   soap-env:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">
                    <soap-env:Body>
                      <m:contactInfo>
                        <Item xsi:type="xsd:string">1234abc</Item>
                        <contact>
                          <firstName xsi:type="xsd:string">Manuel</firstName>
                          <lastName xsi:type="xsd:string">Rubio</lastName>
                        </contact>
                      </m:contactInfo>
                    </soap-env:Body>
                  </soap-env:Envelope>| == Proximal.to_xmlel(soap)
    end

    test "new with an Apache Axis Map (ns2:Map) argument" do
      soap =
        Soap.new(
          "contactCreate",
          ["1234abc", {"additional", %Soap.ApacheMap{value: %{"ES_NIF" => "B85819159", "ES_TIPO" => "1"}}}],
          "urn:DRS"
        )

      assert ~x|<soap-env:Envelope xmlns:m="urn:DRS"
                                   xmlns:ns2="http://xml.apache.org/xml-soap"
                                   xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                                   xmlns:xsd="http://www.w3.org/2001/XMLSchema"
                                   xmlns:soap-enc="http://schemas.xmlsoap.org/soap/encoding/"
                                   xmlns:soap-env="http://schemas.xmlsoap.org/soap/envelope/"
                                   soap-env:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">
                    <soap-env:Body>
                      <m:contactCreate>
                        <Item xsi:type="xsd:string">1234abc</Item>
                        <additional xsi:type="ns2:Map">
                          <item>
                            <key xsi:type="xsd:string">ES_NIF</key>
                            <value xsi:type="xsd:string">B85819159</value>
                          </item>
                          <item>
                            <key xsi:type="xsd:string">ES_TIPO</key>
                            <value xsi:type="xsd:string">1</value>
                          </item>
                        </additional>
                      </m:contactCreate>
                    </soap-env:Body>
                  </soap-env:Envelope>| == Proximal.to_xmlel(soap)
    end

    test "an empty Soap.ApacheMap still gets the ns2:Map type" do
      soap = Soap.new("contactCreate", [{"additional", %Soap.ApacheMap{value: %{}}}], "urn:DRS")

      assert ~x|<soap-env:Envelope xmlns:m="urn:DRS"
                                   xmlns:ns2="http://xml.apache.org/xml-soap"
                                   xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                                   xmlns:xsd="http://www.w3.org/2001/XMLSchema"
                                   xmlns:soap-enc="http://schemas.xmlsoap.org/soap/encoding/"
                                   xmlns:soap-env="http://schemas.xmlsoap.org/soap/envelope/"
                                   soap-env:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">
                    <soap-env:Body>
                      <m:contactCreate>
                        <additional xsi:type="ns2:Map"/>
                      </m:contactCreate>
                    </soap-env:Body>
                  </soap-env:Envelope>| == Proximal.to_xmlel(soap)
    end

    test "Soap.ApacheMap's namespace prefix and URI are overridable" do
      soap =
        Soap.new(
          "contactCreate",
          [
            {"additional",
             %Soap.ApacheMap{
               value: %{"A" => "1"},
               namespace_prefix: "other",
               namespace_uri: "urn:other-map"
             }}
          ],
          "urn:DRS"
        )

      assert ~x|<soap-env:Envelope xmlns:m="urn:DRS"
                                   xmlns:other="urn:other-map"
                                   xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                                   xmlns:xsd="http://www.w3.org/2001/XMLSchema"
                                   xmlns:soap-enc="http://schemas.xmlsoap.org/soap/encoding/"
                                   xmlns:soap-env="http://schemas.xmlsoap.org/soap/envelope/"
                                   soap-env:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">
                    <soap-env:Body>
                      <m:contactCreate>
                        <additional xsi:type="other:Map">
                          <item>
                            <key xsi:type="xsd:string">A</key>
                            <value xsi:type="xsd:string">1</value>
                          </item>
                        </additional>
                      </m:contactCreate>
                    </soap-env:Body>
                  </soap-env:Envelope>| == Proximal.to_xmlel(soap)
    end

    test "a Decimal value still uses its own dedicated encoding, not the Any fallback" do
      soap = Soap.new("domainInfo", [{"price", Decimal.new("12.50")}], "urn:DRS")

      assert ~x|<soap-env:Envelope xmlns:m="urn:DRS"
                                   xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                                   xmlns:xsd="http://www.w3.org/2001/XMLSchema"
                                   xmlns:soap-enc="http://schemas.xmlsoap.org/soap/encoding/"
                                   xmlns:soap-env="http://schemas.xmlsoap.org/soap/envelope/"
                                   soap-env:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">
                    <soap-env:Body>
                      <m:domainInfo>
                        <price xsi:type="xsd:decimal">12.50</price>
                      </m:domainInfo>
                    </soap-env:Body>
                  </soap-env:Envelope>| == Proximal.to_xmlel(soap)
    end

    test "new with named and list of nested parameters" do
      soap =
        Soap.new(
          "contactList",
          ["1234abc", {"contacts", [[{"firstName", "Manuel"}, {"lastName", "Rubio"}]]}],
          "urn:DRS"
        )

      assert ~x|<soap-env:Envelope xmlns:m="urn:DRS"
                                   xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                                   xmlns:xsd="http://www.w3.org/2001/XMLSchema"
                                   xmlns:soap-enc="http://schemas.xmlsoap.org/soap/encoding/"
                                   xmlns:soap-env="http://schemas.xmlsoap.org/soap/envelope/"
                                   soap-env:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">
                    <soap-env:Body>
                      <m:contactList>
                        <Item xsi:type="xsd:string">1234abc</Item>
                        <contacts>
                          <Item>
                            <firstName xsi:type="xsd:string">Manuel</firstName>
                            <lastName xsi:type="xsd:string">Rubio</lastName>
                          </Item>
                        </contacts>
                      </m:contactList>
                    </soap-env:Body>
                  </soap-env:Envelope>| == Proximal.to_xmlel(soap)
    end
  end
end
