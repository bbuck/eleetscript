module Cuby
  class ListBase
    attr_reader :array, :hash

    def initialize(nil_val)
      @array = []
      @hash = Hash.new(nil_val)
    end
  end
end