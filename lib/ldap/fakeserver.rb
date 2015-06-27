require 'ldap/fakeserver/version'
require 'ldap/server'

require_relative 'fakeserver/dn'

module LDAP
  module FakeServer
    class Operation < LDAP::Server::Operation
      def initialize(conn, msgid, mutex, directory)
        super(conn, msgid)
        @directory = directory
      end

      def search(basedn, scope, deref, filter)
        basedn = Dn.parse(basedn)

        exists = false
        @directory.each do |dn, entry|
          dn = Dn.parse(dn)
          if in_scope(scope, basedn, dn)
            send_SearchResultEntry(dn.to_s, entry) if LDAP::Server::Filter.run(filter, entry)
            exists = true
          end
        end
        raise LDAP::ResultError::NoSuchObject unless exists
      end

      private

      def in_scope(scope, basedn, dn)
        case scope
        when LDAP::Server::BaseObject
          basedn == dn
        when LDAP::Server::SingleLevel
          basedn.suffix_of?(dn) and basedn.length + 1 == dn.length
        when LDAP::Server::WholeSubtree
          basedn.suffix_of?(dn)
        else
          raise LDAP::ResultError::UnwillingToPerform, 'unrecognized search scope'
        end
      end
    end

    class Server < LDAP::Server

      def initialize(directory = {}, opt = {})
        @directory = directory

        opt = {
          bindaddr: '127.0.0.1',
          port: 33389,
          operation_class: Operation,
          operation_args: [Mutex.new, @directory]
        }.merge(opt)

        super(opt)
      end

    end
  end
end
