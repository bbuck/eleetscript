module EleetScript
  class ProcessedKeyHash < Hash
    def initialize(*args)
      super(*args)
      @key_preprocessor = nil
    end

    def set_key_preprocessor(&block)
      if block_given?
        @key_preprocessor = block
      end
    end

    def [](key)
      key = adjust(key)
      super(key)
    end

    def []=(key, value)
      key = adjust(key)
      super(key, value)
    end

    private

    def adjust(key)
      if @key_preprocessor && @key_preprocessor.respond_to?(:call)
        @key_preprocessor.call(key)
      else
        key
      end
    end
  end
end