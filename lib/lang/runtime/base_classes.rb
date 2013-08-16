module Cuby
  class ListBase
    attr_reader :array, :hash

    def initialize(nil_val)
      @array = []
      @hash = Hash.new(nil_val)
    end

    def merge!(o)
      @array.concat(o.array)
      @hash.merge!(o.hash)
    end

    def dup
      lst = ListBase.new
      lst.array = @array.dup
      lst.hash = @hash.dup
      lst
    end
  end
end