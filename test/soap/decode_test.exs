defmodule Soap.DecodeTest do
  use ExUnit.Case

  test "decode simple response" do
    envelope = ~s|<SOAP-ENV:Envelope xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/"
                                     xmlns:ns1="urn:DRS"
                                     xmlns:xsd="http://www.w3.org/2001/XMLSchema"
                                     xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                                     xmlns:SOAP-ENC="http://schemas.xmlsoap.org/soap/encoding/"
                                     SOAP-ENV:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">
                    <SOAP-ENV:Body>
                      <ns1:sessionOpenResponse>
                        <IDSession xsi:type="xsd:string">1234abc</IDSession>
                      </ns1:sessionOpenResponse>
                    </SOAP-ENV:Body>
                  </SOAP-ENV:Envelope>|

    assert Soap.Decode.decode(envelope) == %{"IDSession" => "1234abc"}
  end

  test "decode complex response" do
    envelope =
      ~s|<SOAP-ENV:Envelope xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/"
                            xmlns:ns1="urn:DRS"
                            xmlns:xsd="http://www.w3.org/2001/XMLSchema"
                            xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                            xmlns:ns2="http://xml.apache.org/xml-soap"
                            xmlns:SOAP-ENC="http://schemas.xmlsoap.org/soap/encoding/"
                            SOAP-ENV:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">
          <SOAP-ENV:Body>
            <ns1:contactInfoResponse>
              <contact xsi:type="ns1:StructContactReturn">
                <idContact xsi:type="xsd:string">XX123</idContact>
                <firstName xsi:type="xsd:string">Manuel</firstName>
                <lastName xsi:type="xsd:string">Rubio</lastName>
                <bodyName xsi:type="xsd:string"/>
                <address>
                  <country xsi:type="xsd:string">ES</country>
                  <state xsi:type="xsd:string">Córdoba</state>
                </address>
                <isOwner xsi:type="xsd:int">0</isOwner>
              </contact>
            </ns1:contactInfoResponse>
          </SOAP-ENV:Body>
        </SOAP-ENV:Envelope>|

    assert %{
      "contact" => %{
        "address" => %{
          "country" => "ES",
          "state" => "Córdoba"
        },
        "bodyName" => nil,
        "firstName" => "Manuel",
        "idContact" => "XX123",
        "isOwner" => "0",
        "lastName" => "Rubio"
      }
    } == Soap.Decode.decode(envelope)
  end

  test "decode item list response" do
    envelope =
      ~s|<SOAP-ENV:Envelope xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/"
                            xmlns:ns1="urn:DRS"
                            xmlns:xsd="http://www.w3.org/2001/XMLSchema"
                            xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                            xmlns:ns2="http://xml.apache.org/xml-soap"
                            xmlns:SOAP-ENC="http://schemas.xmlsoap.org/soap/encoding/"
                            SOAP-ENV:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">
          <SOAP-ENV:Body>
            <ns1:contactInfoResponse>
              <contactList xsi:type="ns1:StructContactReturn">
                <allowedIds>
                  <item xsi:type="xsd:string">XX123</item>
                  <item xsi:type="xsd:string">YY123</item>
                  <item xsi:type="xsd:string">ZZ123</item>
                </allowedIds>
                <bannedIds/>
              </contactList>
            </ns1:contactInfoResponse>
          </SOAP-ENV:Body>
        </SOAP-ENV:Envelope>|

    assert %{
      "contactList" => ~w[ XX123 YY123 ZZ123 ]
    } == Soap.Decode.decode(envelope)
  end
end
