require "bigdecimal"
require "engine/eleet_to_ruby_wrapper"
require "engine/ruby_to_eleet_wrapper"
require "engine/esproc"
require "engine/ruby_lambda"

module EleetScript
  module Values
    class << self
      def to_eleet_value(ruby_obj, engine, options = {})
        memory = if engine.kind_of?(Memory)
          engine
        else
          engine.memory
        end
        if ruby_obj.kind_of?(EleetToRubyWrapper)
          ruby_obj.instance_variable_get("@eleet_obj")
        elsif ruby_obj.kind_of?(String)
          memory.root_namespace["String"].new_with_value(ruby_obj, memory.root_namespace)
        elsif ruby_obj.kind_of?(Symbol)
          memory.root_namespace["Symbol"].new_with_value(ruby_obj, memory.root_namespace)
        elsif ruby_obj.kind_of?(Fixnum)
          memory.root_namespace["Integer"].new_with_value(ruby_obj, memory.root_namespace)
        elsif ruby_obj.kind_of?(Float)
          memory.root_namespace["Float"].new_with_value(ruby_obj, memory.root_namespace)
        elsif ruby_obj.kind_of?(BigDecimal)
          memory.root_namespace["Integer"].new_with_value(ruby_obj.to_i, memory.root_namespace)
        elsif ruby_obj.kind_of?(Proc)
          memory.root_namespace["Lambda"].new_with_value(ESProc.new(ruby_obj, engine), memory.root_namespace)
        elsif ruby_obj.kind_of?(RubyLambda)
          ruby_obj.es_lambda
        elsif ruby_obj.kind_of?(Regexp)
          memory.root_namespace["Regex"].new_with_value(ESRegex.from_regex(ruby_obj), memory.root_namespace)
        elsif ruby_obj.kind_of?(ESRegex)
          memory.root_namespace["Regex"].new_with_value(ruby_obj, memory.root_namespace)
        elsif ruby_obj.nil?
          memory.root_namespace["nil"]
        elsif ruby_obj == true
          memory.root_namespace["true"]
        elsif ruby_obj == false
          memory.root_namespace["false"]
        else
          RubyToEleetWrapper.new(ruby_obj, engine, options)
        end
      end

      def to_ruby_value(eleet_obj, engine)
        ruby_values = ["TrueClass", "FalseClass", "NilClass", "String", "Integer", "Float", "Regex", "Symbol"]
        if eleet_obj.kind_of?(RubyToEleetWrapper)
          eleet_obj.instance_variable_get("@ruby_obj")
        elsif eleet_obj.class_name == "Lambda"
          if eleet_obj.ruby_value.is_a?(ESProc)
            eleet_obj.ruby_value.proc
          else
            proc = RubyLambda.new do |*args|
              eleet_args = args.map do |arg|
                to_eleet_value(arg, engine)
              end
              to_ruby_value(eleet_obj.call(:call, eleet_args), engine)
            end
            proc.es_lambda = eleet_obj
            proc
          end
        elsif ruby_values.include?(eleet_obj.class_name)
          eleet_obj.ruby_value
        else
          EleetToRubyWrapper.new(eleet_obj, engine)
        end
      end
    end
  end
end
