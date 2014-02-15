module EleetScript
  class ListBase
    attr_reader :array_value, :hash_value

    def initialize(nil_val)
      @array_value = []
      @hash_value = Hash.new(nil_val)
    end

    def merge!(o)
      @array_value.concat(o.array_value)
      @hash_value.merge!(o.hash_value)
    end

    def clone
      dup
    end

    def dup
      lst = ListBase.new
      lst.array_value = @array_value.dup
      lst.hash_value = @hash_value.dup
      lst
    end

    def clear
      @array_value.clear
      @hash_value.clear
    end
  end

  class ESRegex < Regexp
    attr_writer :global

    class << self
      def from_regex(regex)
        ESRegex.new(regex.source, regex.flags)
      end
    end

    def initialize(pattern, flags = nil)
      flag_num = 0
      if flags.is_a?(String)
        flags = flags ? flags.chars : []
        @global = true if flags.include?("g")
        flag_num |= Regexp::IGNORECASE if flags.include?("i")
        flag_num |= Regexp::MULTILINE if flags.include?("m")
      else
        flag_num = flags
      end
      super(pattern, flag_num)
    end

    def global?
      @global || false
    end

    def ignorecase?
      options & Regexp::IGNORECASE == Regexp::IGNORECASE
    end

    def multiline?
      options & Regexp::MULTILINE == Regexp::MULTILINE
    end

    def flags
      flags = ""
      flags += "m" if options & Regexp::MULTILINE == Regexp::MULTILINE
      flags += "i" if options & Regexp::IGNORECASE == Regexp::IGNORECASE
      flags += "g" if global?
      flags
    end
  end
end