module EleetScript
  class EleetToRubyWrapper
    def initialize(eleet_obj, engine)
      @eleet_obj = eleet_obj
      @engine = engine
    end

    def call(method, *args, &block)
      eleet_args = args.map { |a| Values.to_eleet_value(a, @engine) }
      eleet_args << Values.to_eleet_value(block, @engine) if block_given?
      Values.to_ruby_value(@eleet_obj.call(method, eleet_args), @engine)
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
        call(:class)
      end
    end

    def to_s
      call(:to_string)
    end
  end
end