require 'parslet'

module LDAP::FakeServer
  # This class parses string representation of DNs as defined in RFC4514.
  class DnParser < Parslet::Parser
    root :dn

    rule(:space?) { str(' ').repeat }

    rule(:dn) { (rdn >> (str(',') >> rdn).repeat).repeat(0,1).as(:dn) }
    rule(:rdn) { (attr >> (str('+') >> attr).repeat).as(:rdn) }
    rule(:attr) { attr_type.as(:type) >> str('=') >> attr_value.as(:value) }
    rule(:attr_type) { keystring | numericoid }
    rule(:attr_value) { hexstring | string  }

    rule(:keystring) { match['A-Za-z'] >> match['A-Za-z0-9-'].repeat }
    rule(:number) { str('0') | match['1-9'] >> match['0-9'].repeat }
    rule(:numericoid) { number >> (str('.') >> number).repeat }

    # relaxed rule allowing trailing spaces (which are later stripped)
    rule(:string) { (stringchar >> (stringchar | str('#')).repeat).maybe }
    rule(:stringchar) { match['^#"+,;<>\\\\'] | escpair }

    rule(:escpair) { str('\\') >> (match[' "#+,;<=>\\\\'] | hexpair) }
    rule(:hexstring) { str('#') >> hexpair.repeat }
    rule(:hexpair) { match['0-9a-fA-F'].repeat(2,2) }
  end

  class DnTransform < Parslet::Transform
    rule(type: simple(:type), value: simple(:value)) {
      str = value.to_s.strip
      if str.start_with?('#')
        str = [str[1..-1]].pack('H*')
      else
        str = str.encode(Encoding::UTF_8).b
        str.gsub!(/\\([0-9a-fA-F]{2})/) { sprintf('%c'.b, $1.hex) }
        str.gsub!(/\\(.)/, '\1')
        str.force_encoding(Encoding::UTF_8)
      end
      Attr.new(type.to_s, str)
    }
    rule(rdn: simple(:attr)) { Rdn[attr] }
    rule(rdn: sequence(:attrs)) { Rdn[*attrs] }
    rule(dn: simple(:rdn)) { Dn[rdn] }
    rule(dn: sequence(:rdns)) { Dn[*rdns.reverse] }
  end

  class Attr
    attr_accessor :type, :value

    def initialize(type, value)
      @type = type
      @value = value
    end

    def eql?(other)
      type.downcase == other.type.downcase && value == other.value
    end

    alias_method :==, :eql?

    def hash
      [type.downcase, value.downcase].hash
    end

    def inspect
      "#{@type}=#{@value}"
    end
  end


  class Rdn < Array
    def inspect
      map(&:inspect).join('+')
    end
  end

  class Dn < Array
    @@parser = DnParser.new
    @@transf = DnTransform.new

    def inspect
      "<DN #{map(&:inspect).join(',')}>"
    end

    def suffix_of?(other)
      zip(other).all? {|a, b| a == b }
    end

    class << self
      def parse(str)
        @@transf.apply(@@parser.parse(str))
      end
    end
  end
end
