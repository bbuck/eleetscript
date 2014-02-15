module EleetScript
  class RubyToEleetWrapper
    def initialize(ruby_obj, engine)
      @ruby_obj = ruby_obj
      @engine = engine
    end

    def call(method_name, args)
      if method_name.to_sym == :to_string
        method_name = :to_s
      elsif method_name.to_sym == :class_name
        cls = if @ruby_obj.class == Class
          @ruby_obj
        else
          @ruby_obj.class
        end
        return Values.to_eleet_value(cls.name, @engine)
      end
      ruby_args = args.map { |arg| Values.to_ruby_value(arg, @engine) }
      block = if ruby_args.length > 0 && ruby_args.last.is_a?(RubyLambda)
        ruby_args.pop
      else
        nil
      end
      begin
        Values.to_eleet_value(@ruby_obj.send(method_name, *ruby_args, &block), @engine)
      rescue NoMethodError => e
        Values.to_eleet_value(@engine.get("nil"), @engine)
      end
    end

    def raw
      @ruby_obj
    end

    def is_a?(name)
      cls = if @ruby_obj.class == Class
        @ruby_obj
      else
        @ruby_obj.class
      end
      cls_names = cls.ancestors.map { |a| a.name.split("::").last }
      Values.to_eleet_value(cls_names.include?(name), @engine)
    end

    def class?
      Values.to_eleet_value(@ruby_obj.class == Class, @engine)
    end

    def instance?
      !class?
    end

    def name
      if @ruby_obj.class == Class
        @ruby_obj.name
      else
        @ruby_obj.class.name
      end
    end

    def runtime_class
      cls = if @ruby_obj.class == Class
        @ruby_obj
      else
        @ruby_obj.class
      end
      Values.to_eleet_value(cls)
    end
  end
end
