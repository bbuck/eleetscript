module Cuby
  class ListBase
    attr_reader :array, :hash

    def initialize(nil_val)
      @array = []
      @hash = Hash.new(nil_val)
    end

    def dup
      lst = ListBase.new
      lst.array = @array.dup
      lst.hash = @hash.dup
      lst
    end
  end
end