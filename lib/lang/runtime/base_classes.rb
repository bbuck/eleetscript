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
end