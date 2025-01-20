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

  test "decode error" do
    envelope = ~s|<SOAP-ENV:Envelope xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/">
          <SOAP-ENV:Body>
            <SOAP-ENV:Fault>
              <faultcode>E13</faultcode>
              <faultstring>E13 : Province : Invalid value</faultstring>
            </SOAP-ENV:Fault>
          </SOAP-ENV:Body>
        </SOAP-ENV:Envelope>|

    assert %{"faultcode" => "E13", "faultstring" => "E13 : Province : Invalid value"} ==
             Soap.Decode.decode(envelope)
  end

  test "decode complex response" do
    envelope = ~s|<SOAP-ENV:Envelope xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/"
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
               "bodyName" => "",
               "firstName" => "Manuel",
               "idContact" => "XX123",
               "isOwner" => 0,
               "lastName" => "Rubio"
             }
           } == Soap.Decode.decode(envelope)
  end

  test "decode custom complex response" do
    envelope = ~s|<SOAP-ENV:Envelope xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/"
                            xmlns:ns1="urn:DRS"
                            xmlns:SOAP-ENC="http://schemas.xmlsoap.org/soap/encoding/"
                            xmlns:xsd="http://www.w3.org/2001/XMLSchema"
                            xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                            SOAP-ENV:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">
          <SOAP-ENV:Body>
            <ns1:domainCheckResponse>
              <domainCheckResponseReturn SOAP-ENC:arrayType="ns1:StructDomainCheckResponse[1]" xsi:type="ns1:ArrayStructDomainCheckResponse">
                <item xsi:type="ns1:StructDomainCheckResponse">
                  <domain xsi:type="xsd:string">altenwald.se</domain>
                  <result xsi:type="xsd:string">AVAILABLE</result>
                  <reason xsi:type="xsd:string"></reason>
                </item>
              </domainCheckResponseReturn>
            </ns1:domainCheckResponse>
          </SOAP-ENV:Body>
        </SOAP-ENV:Envelope>|

    assert %{
             "domainCheckResponseReturn" => [
               %{
                 "domain" => "altenwald.se",
                 "result" => "AVAILABLE",
                 "reason" => ""
               }
             ]
           } == Soap.Decode.decode(envelope)
  end

  test "decode array of strings" do
    envelope = ~s|<SOAP-ENV:Envelope xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/"
                            xmlns:ns1="urn:DRS"
                            xmlns:xsd="http://www.w3.org/2001/XMLSchema"
                            xmlns:SOAP-ENC="http://schemas.xmlsoap.org/soap/encoding/"
                            SOAP-ENV:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">
                    <SOAP-ENV:Body>
                      <ns1:domainTldInfoResponse>
                        <return xsi:type="ns1:StructDomainTldInfo">
                          <tld xsi:type="xsd:string">com</tld>
                          <Country xsi:nil="true"/>
                          <Extensions SOAP-ENC:arrayType="ns1:StructTld[3]" xsi:type="ns1:ArrayOfStructTld">
                            <item xsi:type="ns1:StructTld">
                              <type xsi:type="xsd:string">popular</type>
                              <tld SOAP-ENC:arrayType="xsd:string[1]" xsi:type="ns1:ArrayOfString">
                                <item xsi:type="xsd:string">com</item>
                              </tld>
                            </item>
                            <item xsi:type="ns1:StructTld">
                              <type xsi:type="xsd:string">functional</type>
                              <tld xsi:nil="true" xsi:type="ns1:ArrayOfString"/>
                            </item>
                            <item xsi:type="ns1:StructTld">
                              <type xsi:type="xsd:string">regional</type>
                              <tld xsi:nil="true" xsi:type="ns1:ArrayOfString"/>
                            </item>
                          </Extensions>
                          <PeriodCreate xsi:type="xsd:string">1-10</PeriodCreate>
                          <PeriodRenew xsi:type="xsd:string">1-10</PeriodRenew>
                          <DelaiRenewBeforeExpiration xsi:type="xsd:int">3650</DelaiRenewBeforeExpiration>
                          <DelaiRenewAfterExpiration xsi:type="xsd:int">30</DelaiRenewAfterExpiration>
                          <DelaiRestoreAfterDelete xsi:type="xsd:int">30</DelaiRestoreAfterDelete>
                          <HasEppCode xsi:type="xsd:int">1</HasEppCode>
                          <HasRegistrarLock xsi:type="xsd:int">1</HasRegistrarLock>
                          <HasAutorenew xsi:type="xsd:int">1</HasAutorenew>
                          <HasWhoisPrivacy xsi:type="xsd:int">1</HasWhoisPrivacy>
                          <HasMultipleCheck xsi:type="xsd:int">1</HasMultipleCheck>
                          <HasImmediateDelete xsi:type="xsd:int">1</HasImmediateDelete>
                          <HasTrusteeService xsi:type="xsd:int">0</HasTrusteeService>
                          <HasLocalContactService xsi:type="xsd:int">0</HasLocalContactService>
                          <HasZonecheck xsi:type="xsd:int">0</HasZonecheck>
                          <HasDnsSec xsi:type="xsd:int">1</HasDnsSec>
                          <FeeCurrency xsi:type="xsd:string">EUR</FeeCurrency>
                          <Fee4Registration xsi:type="xsd:double">8.8</Fee4Registration>
                          <Fee4Renewal xsi:type="xsd:double">8.8</Fee4Renewal>
                          <Fee4Transfer xsi:type="xsd:double">8.8</Fee4Transfer>
                          <Fee4Trade xsi:type="xsd:double">0</Fee4Trade>
                          <Fee4Restore xsi:type="xsd:double">42.8</Fee4Restore>
                          <Fee4TrusteeService xsi:type="xsd:double">0</Fee4TrusteeService>
                          <Fee4LocalContactService xsi:type="xsd:double">0</Fee4LocalContactService>
                          <Informations xsi:type="xsd:string"></Informations>
                        </return>
                      </ns1:domainTldInfoResponse>
                    </SOAP-ENV:Body>
                  </SOAP-ENV:Envelope>|

    assert %{
             "return" => %{
               "Country" => nil,
               "DelaiRenewAfterExpiration" => 30,
               "DelaiRenewBeforeExpiration" => 3650,
               "DelaiRestoreAfterDelete" => 30,
               "Extensions" => [
                 %{"tld" => ["com"], "type" => "popular"},
                 %{"tld" => nil, "type" => "functional"},
                 %{"tld" => nil, "type" => "regional"}
               ],
               "Fee4LocalContactService" => 0.0,
               "Fee4Registration" => 8.8,
               "Fee4Renewal" => 8.8,
               "Fee4Restore" => 42.8,
               "Fee4Trade" => 0.0,
               "Fee4Transfer" => 8.8,
               "Fee4TrusteeService" => 0.0,
               "FeeCurrency" => "EUR",
               "HasAutorenew" => 1,
               "HasDnsSec" => 1,
               "HasEppCode" => 1,
               "HasImmediateDelete" => 1,
               "HasLocalContactService" => 0,
               "HasMultipleCheck" => 1,
               "HasRegistrarLock" => 1,
               "HasTrusteeService" => 0,
               "HasWhoisPrivacy" => 1,
               "HasZonecheck" => 0,
               "Informations" => "",
               "PeriodCreate" => "1-10",
               "PeriodRenew" => "1-10",
               "tld" => "com"
             }
           } == Soap.Decode.decode(envelope)
  end

  test "decode item list response" do
    envelope = ~s|<SOAP-ENV:Envelope xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/"
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
                  <Item xsi:type="xsd:string">XX123</Item>
                  <Item xsi:type="xsd:string">YY123</Item>
                  <Item xsi:type="xsd:string">ZZ123</Item>
                </allowedIds>
                <bannedIds xsi:type="ns2:Map"/>
              </contactList>
            </ns1:contactInfoResponse>
          </SOAP-ENV:Body>
        </SOAP-ENV:Envelope>|

    assert %{
             "contactList" => %{
               "allowedIds" => ~w[ XX123 YY123 ZZ123 ],
               "bannedIds" => %{}
             }
           } == Soap.Decode.decode(envelope)
  end

  test "decode item list request" do
    envelope = ~s|<?xml version="1.0" encoding="UTF-8"?>
                  <soap-env:Envelope xmlns:m="urn:DRS"
                                     xmlns:soap-enc="http://schemas.xmlsoap.org/soap/encoding/"
                                     xmlns:soap-env="http://schemas.xmlsoap.org/soap/envelope/"
                                     xmlns:xsd="http://www.w3.org/2001/XMLSchema"
                                     xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                                     soap-env:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">
                    <soap-env:Body>
                      <m:sessionOpen>
                        <Item xsi:type="xsd:string">NETIMUSER</Item>
                        <Item xsi:type="xsd:string">NETIMPASS</Item>
                        <Item xsi:type="xsd:string">EN</Item>
                      </m:sessionOpen>
                    </soap-env:Body>
                  </soap-env:Envelope>|

    assert ["NETIMUSER", "NETIMPASS", "EN"] == Soap.Decode.decode(envelope)
  end
end
