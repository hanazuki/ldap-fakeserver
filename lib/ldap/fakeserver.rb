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
        basedn.downcase!

        case scope
        when LDAP::Server::BaseObject
          entry = @directory[basedn]
          raise LDAP::ResultError::NoSuchObject unless entry
          send_SearchResultEntry(basedn, entry) if LDAP::Server::Filter.run(filter, entry)
        when LDAP::Server::SingleLevel
          raise LDAP::ResultError::UnwillingToPerform, 'not implemented'
        when LDAP::Server::WholeSubtree
          raise LDAP::ResultError::UnwillingToPerform, 'not implemented'
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

        super(DEFAULT_OPT.merge(opt))
      end

    end
  end
end
