module PhoneWrangler

  class PhoneNumber

    NUMBER_PARTS = [:area_code, :prefix, :number, :extension]
    attr_accessor :area_code, :prefix, :number, :extension

    unless defined? @@default_area_code
      @@default_area_code = nil
    end

    def self.default_area_code
      @@default_area_code
    end

    def self.default_area_code=(val)
      @@default_area_code = val
    end

    def default_area_code
      @@default_area_code
    end

    @@formats = {
            :us => "%c (%a) %m-%p x %x",
            :us_short => "(%a) %m-%p",
            :nanp_short => "(%a) %m-%p"
    }

    @@pattern_map = {
            /%c/ => :country_code,
            /%a/ => :area_code,
            /%p/ => :prefix,
            /%n/ => :number,
            /%e/ => :extension
    }

    #-------------------args-----------------------------------------
    def initialize(args='')
      @original = args
      self.raw = args
    end

    def raw= (args)
      case args
      when String
        parse_from_string(args)
      when Hash
        args = { :area_code => PhoneNumber.default_area_code }.merge(args)
        NUMBER_PARTS.each do |key|
          send("#{key}=", args[key]) if args[key]
        end
      when Array
        self.pack!(args)
      else
        raise ArgumentError.new("Sorry, can't handle arguments of type #{args.class}")
      end
    end

    def has_area_code?
      ! area_code.nil?
    end

    def == other
      case other
      when PhoneNumber
        self.unpack == other.unpack
      when String, Hash
        self.unpack == PhoneNumber.new(other).unpack
      else
        false
      end
    end

    def empty?
      answer = true
      NUMBER_PARTS.each do |field|
        if self.respond_to?(field)
          field_val = self.send(field)
          answer = answer && (field_val.nil? || field_val.empty?)
        end
      end
      return answer
    end

    #------------------------------------------------------------
    def to_s(format = '')
      return '' if self.empty?

      case format
      when Symbol
        format = @@formats[format]
      when ''
        format += "(%a) " unless area_code.nil? or area_code.empty?
        format += "%p-" unless prefix.nil? or prefix.empty?
        format += "%n" unless number.nil? or number.empty?
        format += " x%e" unless extension.nil? or extension.empty?
      end

      format_number(format)
    end

    def original
      @original
    end

    # TODO: Should #digits method include the extension digits at all?  Probably not
    # with an 'x', anyway.
    def digits
      digitstring = ''
      [:area_code, :prefix, :number].each {|part|
        digitstring += self.send(part).to_s unless self.send(part).nil?
      }
      digitstring += " x#{extension}" unless extension.nil?
      digitstring
    end

    # There are lots of regexp-for-phone-number dissussions, but I found this one most useful:
    #   http://stackoverflow.com/questions/123559/a-comprehensive-regex-for-phone-number-validation
    # Nice discussion here, and it had this one, which became the germ of mine.  I added optional
    # parentheses around the area code, the /x and spacing for readability, and changed out \W for
    # [.\/-] for the delimiters to tighten what I'd accept a little bit.
    #
    # The original was (in perl)
    #   my $us_phone_regex = '1?\s*\W\s*([2-9][0-8][0-9])\W*([2-9][0-9]{2})\W*([0-9]{4})(\se?x?t?(\d*))?';

    def parse_from_string(raw_string)
      # Optional +  1 -./ 256 (opt) 456 -./ 1234 ext(opt) 1234 (opt)
      phone_regexp = / \+? \s* 1? \s* [.\/-]? \s*
                       [\(]?([2-9][0-8]\d)?[\)]? \s* [.\/-]? \s*
                       ([2-9]\d{2}) \s* [.\/-]? \s*
                       (\d{4}) \s* (?:\s*e?x?t?\s*(\d+))? /x
      match = phone_regexp.match(raw_string)
      if ! match.nil?
        # puts "Setting values #{match.captures.pretty_inspect}"
        @area_code = match.captures[0]
        @prefix = match.captures[1]
        @number = match.captures[2]
        @extension = match.captures[3]
      else
        # puts "No matchy :("
      end

      if ! default_area_code.nil? and ( @area_code.nil? or @area_code.empty? )
        @area_code = default_area_code
      end
    end

    #------------------------------------------------------------
    def pack(args)

      phArea    = ''
      phPrefix  = ''
      phNumber  = ''
      phExtension  = ''

      if args.size >= 3
        phArea    = args[0].to_s
        phPrefix  = args[1].to_s
        phNumber  = args[3].to_s
        if args.size == 4
          phExtension  = args[4].to_s
        end
      end

      return phArea + phPrefix + phNumber + phExtension
    end

    #------------------------------------------------------------
    def pack!(args)
      @phone_number = pack(args)
    end

    #------------------------------------------------------------
    def unpack
      return {
        :area_code => area_code,
        :prefix => prefix,
        :number => number,
        :extension => extension
      }
    end

    # This part borrowed from http://github.com/midas/phone_number/blob/master/lib/phone_number/number.rb
  private

    def format_number(format)
      @@pattern_map.each do |pat, field|
        format = format.gsub( pat, self.send(field) || '' ) if self.respond_to?(field)
      end
      format
    end

  end

end
=begin
   home = PhoneNumber.new('800/555-2468 x012')
# or
   home = PhoneNumber.new
   home.number = "256-777-7650"
# or
#  home = PhoneNumber.new
({:area_code=>'800', :prefix=>'555', :number=>'2020'})

   puts home.original
   puts home.area_code
   puts home.prefix
   puts home.number
   puts home.extension
   puts home.to_s
   puts home.to_s("(%a) %p-%n")
   puts home.pack({:area_code=>'555', :prefix=>'888', :number=>'1212'})
   p home.unpack
   puts home.pack!({:area_code=>'555', :prefix=>'888', :number=>'1212'})
   puts home.formatted

=end

