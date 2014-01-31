module EleetScript
  class MethodHash
    def initialize
      @instance_methods = {}
      @class_methods = {}
    end

    def [](key)
      store = fetch_method_store(key)
      key = clean_key(key)
      store[key]
    end

    def []=(key, value)
      store = fetch_method_store(key)
      key = clean_key(key)
      store[key] = value
    end

    def keys
      keys = @class_methods.keys.map { |k| "@@#{k}" }
      keys += @instance_methods.keys
      keys
    end

    private

    def clean_key(key)
      key[0..1] == "@@" ? key[2..-1] : key
    end

    def fetch_method_store(key)
      if key[0..1] == "@@"
        @class_methods
      else
        @instance_methods
      end
    end
  end
end