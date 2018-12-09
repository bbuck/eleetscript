module EleetScript
  class EleetToRubyWrapper
    def initialize(eleet_obj, engine)
      @eleet_obj = eleet_obj
      @engine = engine
    end

    def call(method, *args, &block)
      eleet_args = args.map { |a| to_eleet_value(a) }
      eleet_args << to_eleet_value(block) if block_given?
      to_ruby_value(@eleet_obj.call(method, eleet_args))
    end

    def method_missing(name, *args, &block)
      if args && args.length > 0
        call(name, *args, &block)
      else
        call(name, &block)
      end
    end

    def raw
      @eleet_obj
    end

    def class(orig = false)
      if orig
        super
      else
        call(:class_ref)
      end
    end

    def to_h
      if call(:responds_to?, :to_list)
        list_hash = call(:to_list).raw.ruby_value.to_h
        {}.tap do |hash|
          list_hash.each do |key, value|
            hash[to_ruby_value(key)] = to_ruby_value(value)
          end
        end
      else
        {}
      end
    end

    def to_s
      call(:to_string)
    end

    def inspect
      "<EleetToRubyWrapper wrapping=#{call(:class_name)}>"
    end

    protected

    def to_ruby_value(eleet_val)
      Values.to_ruby_value(eleet_val, @engine)
    end

    def to_eleet_value(ruby_val)
      Values.to_eleet_value(ruby_val, @engine)
    end
  end
end
