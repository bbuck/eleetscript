module EleetScript
  class EleetToRubyWrapper
    def initialize(eleet_obj, engine)
      @eleet_obj = eleet_obj
      @engine = engine
    end

    def call(method, *args)
      eleet_args = args.map { |a| Values.to_eleet_value(a, @engine) }
      Values.to_ruby_value(@eleet_obj.call(method, eleet_args), @engine)
    end

    def method_missing(name, *args)
      if args && args.length > 0
        call(name, *args)
      else
        call(name)
      end
    end

    def raw
      @eleet_obj
    end
  end
end