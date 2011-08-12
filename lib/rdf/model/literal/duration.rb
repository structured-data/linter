require 'time'
require 'date'

module RDF; class Literal
  ##
  # A duration literal.
  #
  # @see   http://www.w3.org/TR/xmlschema-2/#duration
  # @since 0.2.1
  class Duration < Literal
    DATATYPE = XSD.duration
    GRAMMAR  = %r(\A(-?)P(\d+Y)?(\d+M)?(\d+D)?T?(\d+H)?(\d+M)?([\d\.]+S)?\Z).freeze

    ##
    # * Given a Numeric, assumes that it is milliseconds
    # * Given a String, parse as xsd:duration
    # * Hash form is used for internal representation
    # @param  [Duration, Hash, Numeric, #to_s] value
    # @option options [String] :lexical (nil)
    def initialize(value, options = {})
      @datatype = RDF::URI(options[:datatype] || DATATYPE)
      @string   = options[:lexical] if options.has_key?(:lexical)
      @string   = value if !defined?(@string) && value.is_a?(String)
      @object   = case value
      when Hash
        value = value.dup
        value[:yr] ||= value[:years]
        value[:mo] ||= value[:months]
        value[:da] ||= value[:days]
        value[:hr] ||= value[:hours]
        value[:mi] ||= value[:minutes]
        value[:se] ||= value[:seconds]
        
        value
      when Duration, Numeric
        {:se => value.to_f}
      else
        parse(value.to_s) rescue { }
      end
      @object[:si] ||= 1
    end

    ##
    # Converts this literal into its canonical lexical representation.
    #
    # Also normalizes elements
    #
    # @return [RDF::Literal] `self`
    # @see    http://www.w3.org/TR/xmlschema-2/#dateTime
    def canonicalize!
      @string = @humanize = nil
      if @object[:se].to_i > 60
        m_r = (@object[:se].to_i / 60) - 1
        @object[:se] -=  m_r * 60
        @object[:mi] = @object[:mi].to_i + m_r
      end
      if @object[:mi].to_i > 60
        h_r = (@object[:mi].to_i / 60) - 1
        @object[:mi] -=  h_r * 60
        @object[:hr] = @object[:hr].to_i +  h_r
      end
      if @object[:hr].to_i > 24
        d_r = (@object[:hr].to_i / 24) - 1
        @object[:hr] -=  d_r * 24
        @object[:da] = @object[:da].to_i + d_r
      end
      if @object[:da].to_i > 30
        m_r = (@object[:da].to_i / 30) - 1
        @object[:da] -=  m_r * 30
        @object[:mo] = @object[:mo].to_i + m_r
      end
      if @object[:mo].to_i > 12
        y_r = (@object[:mo].to_i / 12) - 1
        @object[:mo] -=  y_r * 12
        @object[:yr] = @object[:yr].to_i + y_r
      end
      @object.to_s  # site-effect
      self
    end

    ##
    # Returns `true` if the value adheres to the defined grammar of the
    # datatype.
    #
    # Special case for date and dateTime, for which '0000' is not a valid year
    #
    # @return [Boolean]
    # @since  0.2.1
    def valid?
      !!(value =~ GRAMMAR)
    end

    ##
    # Returns the value as a string.
    #
    # @return [String]
    def to_s
      @string ||= begin
        str = @object[:si] < 0 ? "-P" : "P"
        str << "%dY" % @object[:yr].to_i if @object[:yr]
        str << "%dM" % @object[:mo].to_i if @object[:mo]
        str << "%dD" % @object[:da].to_i if @object[:da]
        str << "T" if @object[:hr] || @object[:mi] || @object[:se]
        str << "%dH" % @object[:hr].to_i if @object[:hr]
        str << "%dM" % @object[:mi].to_i if @object[:mi]
        str << "#{sec_str}S" if @object[:se]
      end
    end

    def plural(v, str)
      "#{v} #{str}#{v == 1 ? '' : 's'}" if v
    end
    
    ##
    # Returns a human-readable value for the interval
    def humanize(lang = :en)
      @humanize ||= {}
      @humanize[lang] ||= begin
        # Just english, for now
        ar = []
        ar << plural(@object[:yr], "year")
        ar << plural(@object[:mo], "month")
        ar << plural(@object[:da], "day")
        ar << plural(@object[:hr], "hour")
        ar << plural(@object[:mi], "minute")
        ar << plural(sec_str, "second") if @object[:se]
        ar = ar.compact
        last = ar.pop
        first = ar.join(" ")
        res = first.empty? ? last : "#{first} and #{last}"
        @object[:si] < 0 ? "#{res} ago" : res
      end
    end

    ##
    # Equal compares as DateTime objects
    def ==(other)
      # If lexically invalid, use regular literal testing
      return super unless self.valid?

      case other
      when Duration
        return super unless other.valid?
        self.to_f == something.to_f
      when String
        self.to_s(:xml) == something
      when Numeric
        self.to_f == something
      when Literal::DateTime, Literal::Time, Literal::Date
        false
      else
        super
      end
    end

    # @return [Float]
    def to_f
      ( @object[:yr].to_i * 365 * 24 * 3600 +
        @object[:mo].to_i * 30 * 24 * 3600 +
        @object[:da].to_i * 24 * 3600 +
        @object[:hr].to_i * 3600 +
        @object[:mi].to_i * 60 +
        @object[:se].to_f
      ) * @object[:si]
    end

    # @return [Integer]
    def to_i; Integer(self.to_f); end
    
    private
    # Reverse convert from XSD version of duration
    # XSD allows -P1111Y22M33DT44H55M66.666S with any combination in regular order
    # We assume 1M == 30D, but are out of spec in this regard
    # We only output up to hours
    #
    # @param [String] value XSD formatted duration
    # @return [Duration]
    def parse(value)
      hash = {}
      if value.to_s.match(GRAMMAR)
        hash[:si] = $1 == "-" ? -1 : 1
        hash[:yr] = $2.to_i if $2
        hash[:mo] = $3.to_i if $3
        hash[:da] = $4.to_i if $4
        hash[:hr] = $5.to_i if $5
        hash[:mi] = $6.to_i if $6
        hash[:se] = $7.to_f if $7
        value = hash
      end
    end
    
    def sec_str
      usec = (@object[:se] * 1000).to_i % 1000
      usec > 0 ? ("%2.3f" % @object[:se]).sub(/0*\Z/, '') : @object[:se].to_i.to_s
    end
  end # Duration
end; end # RDF::Literal
