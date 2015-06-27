class DnTest < Minitest::Test
  Dn = LDAP::FakeServer::Dn
  Rdn = LDAP::FakeServer::Rdn
  Attr = LDAP::FakeServer::Attr

  def test_parser
    parser = LDAP::FakeServer::DnParser.new
    transform = LDAP::FakeServer::DnTransform.new

    dns = {
      '' => Dn[],
      'cn=admin' => Dn[Rdn[Attr.new('cn','admin')]],
      'cn=' => Dn[Rdn[Attr.new('cn','')]],
      'cn=,o=' => Dn[Rdn[Attr.new('o','')],Rdn[Attr.new('cn','')]],

      # examples from rfc4514
      'UID=jsmith,DC=example,DC=net' => Dn[Rdn[Attr.new('dc','net')],Rdn[Attr.new('dc','example')],Rdn[Attr.new('uid','jsmith')]],
      'OU=Sales+CN=J.  Smith,DC=example,DC=net' => Dn[Rdn[Attr.new('dc','net')],Rdn[Attr.new('dc','example')],Rdn[Attr.new('ou','Sales'),Attr.new('cn','J.  Smith')]],
      'CN=James \\"Jim\\" Smith\, III,DC=example,DC=net' => Dn[Rdn[Attr.new('dc','net')],Rdn[Attr.new('dc','example')],Rdn[Attr.new('cn','James "Jim" Smith, III')]],
      'CN=Before\\0dAfter,DC=example,DC=net' => Dn[Rdn[Attr.new('dc','net')],Rdn[Attr.new('dc','example')],Rdn[Attr.new('cn',"Before\x0dAfter")]],
      '1.3.6.1.4.1.1466.0=#04024869' => Dn[Rdn[Attr.new('1.3.6.1.4.1.1466.0',"\x04\x02Hi")]],
      'CN=Lu\\C4\\8Di\\C4\\87' => Dn[Rdn[Attr.new('cn',"Lu\u010di\u0107")]],
    }

    dns.each do |str, dn|
      parsed = Dn.parse(str)
      assert_kind_of Dn, parsed
      assert_equal dn, parsed
    end
  end

  def test_suffix_of
    assert Dn[].suffix_of?(Dn[])
    assert !Dn[Rdn[Attr.new('cn','john')]].suffix_of?(Dn[])
    assert Dn[].suffix_of?(Dn[Rdn[Attr.new('cn','john')]])
    assert Dn[Rdn[Attr.new('cn','john')]].suffix_of?(Dn[Rdn[Attr.new('cn','john')]])
    assert !Dn[Rdn[Attr.new('cn','james')]].suffix_of?(Dn[Rdn[Attr.new('cn','john')]])
    assert Dn[Rdn[Attr.new('o','org')]].suffix_of?(Dn[Rdn[Attr.new('o','org')],Rdn[Attr.new('cn','john')]])
    assert !Dn[Rdn[Attr.new('o','org_other')]].suffix_of?(Dn[Rdn[Attr.new('o','org')],Rdn[Attr.new('cn','john')]])
    assert Dn[Rdn[Attr.new('dc','com')],Rdn[Attr.new('dc','example')],Rdn[Attr.new('o','org')]].suffix_of?(Dn[Rdn[Attr.new('dc','com')],Rdn[Attr.new('dc','example')],Rdn[Attr.new('o','org')],Rdn[Attr.new('ou','group')],Rdn[Attr.new('cn','john')]])
    assert !Dn[Rdn[Attr.new('dc','com')],Rdn[Attr.new('dc','example-2')],Rdn[Attr.new('o','org')]].suffix_of?(Dn[Rdn[Attr.new('dc','com')],Rdn[Attr.new('dc','example')],Rdn[Attr.new('o','org')],Rdn[Attr.new('ou','group')],Rdn[Attr.new('cn','john')]])
  end
end
