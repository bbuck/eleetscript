module EleetScript
  class EleetScriptArray < EleetScriptClass
    attr_reader :hash, :array

    def initialize(memory, super_class = nil)
      super(memory, super_class)
      @hash = {}
      @array = []
    end

    def to_s
      str = "<EleetScriptArray"
      hash_data = @hash.map do |key, value|
        "#{key}=#{value}"
      end
      data = @array.dup.concat(hash_data)
      if data.length > 0
        str += "[" + data.join(", ") + "]"
      end
      str + ">"
    end
  end
end