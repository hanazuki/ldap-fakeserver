require 'test_helper'

require 'ldap/fakeserver'

class SimpleTest < Minitest::Test
  PORT = 33389

  def setup
    @directory = {
      'cn=admin' => {'cn' => ['admin']},
      'cn=user1,ou=org,dc=example,dc=com' => {'cn' => ['user1']},
      'cn=user2,ou=org,dc=example,dc=com' => {'cn' => ['user2'], 'mail' => ['u2@example.com']},
      'cn=user3,ou=org,dc=example,dc=com' => {'cn' => ['user3'], 'mail' => ['u3@example.com']},
      'cn=user4,ou=group,ou=org,dc=example,dc=com' => {'cn' => ['user4']},
      'cn=user5,ou=group,ou=org,dc=example,dc=com' => {'cn' => ['user5'], 'mail' => ['u5@example.com']},
    }

    @server = LDAP::FakeServer::Server.new(@directory, port: PORT)
    @server.run_tcpserver

    @client = Net::LDAP.new(host: 'localhost', port: PORT)
  end

  def teardown
    begin
      @server.stop
    rescue Interrupt # exception leaks by bug?
      # nop
    end
  end

  def test_search_baseobject
    result = @client.search(base: 'cn=admin', scope: Net::LDAP::SearchScope_BaseObject)
    assert_equal Net::LDAP::ResultCodeSuccess, @client.get_operation_result.code
    assert_equal 1, result.size
    assert_equal result[0][:cn], ['admin']
  end

  def test_search_baseobject_nonexistent
    result = @client.search(base: 'cn=invalid', scope: Net::LDAP::SearchScope_BaseObject)
    assert_equal Net::LDAP::ResultCodeNoSuchObject, @client.get_operation_result.code
  end

  def test_search_wholesubtree
    result = @client.search(base: 'ou=org,dc=example,dc=com',
                            scope: Net::LDAP::SearchScope_WholeSubtree)
    assert_equal Net::LDAP::ResultCodeSuccess, @client.get_operation_result.code
    assert_equal 5, result.size

    result = @client.search(base: 'ou=group,ou=org,dc=example,dc=com',
                            scope: Net::LDAP::SearchScope_WholeSubtree)
    assert_equal Net::LDAP::ResultCodeSuccess, @client.get_operation_result.code
    assert_equal 2, result.size

    result = @client.search(base: 'ou=org,dc=example,dc=com',
                            scope: Net::LDAP::SearchScope_WholeSubtree,
                            filter: Net::LDAP::Filter.pres('mail'))
    assert_equal Net::LDAP::ResultCodeSuccess, @client.get_operation_result.code
    assert_equal 3, result.size
  end

  def test_search_single_level
    result = @client.search(base: 'ou=org,dc=example,dc=com',
                            scope: Net::LDAP::SearchScope_SingleLevel)
    assert_equal Net::LDAP::ResultCodeSuccess, @client.get_operation_result.code
    assert_equal 3, result.size

    result = @client.search(base: 'ou=org,dc=example,dc=com',
                            scope: Net::LDAP::SearchScope_SingleLevel,
                            filter: Net::LDAP::Filter.pres('mail'))
    assert_equal Net::LDAP::ResultCodeSuccess, @client.get_operation_result.code
    assert_equal 2, result.size
  end
end
