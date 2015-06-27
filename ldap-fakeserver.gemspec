# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'ldap/fakeserver/version'

Gem::Specification.new do |spec|
  spec.name          = 'ldap-fakeserver'
  spec.version       = LDAP::FakeServer::VERSION
  spec.authors       = ['Kasumi Hanazuki']
  spec.email         = ['kasumi@rollingapple.net']
  spec.summary       = %q{A fake LDAP server}
  spec.description   = %q{A fake LDAP server}
  spec.homepage      = 'https://github.com/hanazuki/ldap-fakeserver'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split(?\x0)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.required_ruby_version = '~> 2.0'

  spec.add_dependency 'ruby-ldapserver', '~> 0.5.1'
  spec.add_dependency 'parslet', '~> 1.7.0'

  spec.add_development_dependency 'bundler', '~> 1.7'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'minitest', '~> 5.7'
  spec.add_development_dependency 'net-ldap'
end
