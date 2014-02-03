module EleetScript
  class RubyToEleetWrapper
    def initialize(ruby_obj, engine)
      @ruby_obj = ruby_obj
      @engine = engine
    end

    def call(method_name, args)
      binding.pry
      ruby_args = args.map { |arg| Values.to_ruby_value(arg, @engine) }
      if @ruby_obj.respond_to?(method_name)
        Values.to_eleet_value(@ruby_obj.send(method_name, *ruby_args), @engine)
      else
        Values.to_eleet_value(@engine.get("nil"), @engine)
      end
    end

    def raw
      @ruby_obj
    end
  end
end