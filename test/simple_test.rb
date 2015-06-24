require 'test_helper'

require 'ldap/fakeserver'

class SimpleTest < Minitest::Test
  PORT = 33389

  def setup
    @directory = {
      'cn=admin' => {'cn' => ['admin']}
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
end
