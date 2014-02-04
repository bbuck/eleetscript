require "bigdecimal"
require "engine/eleet_to_ruby_wrapper"
require "engine/ruby_to_eleet_wrapper"
require "engine/esproc"
require "engine/ruby_lambda"

module EleetScript
  module Values
    class << self
      def to_eleet_value(ruby_obj, engine)
        memory = if engine.kind_of?(Memory)
          engine
        else
          engine.instance_variable_get("@memory")
        end
        if ruby_obj.kind_of?(EleetToRubyWrapper)
          ruby_obj.instance_variable_get("@eleet_obj")
        elsif ruby_obj.kind_of?(String)
          memory.root_namespace["String"].new_with_value(ruby_obj)
        elsif ruby_obj.kind_of?(Fixnum)
          memory.root_namespace["Integer"].new_with_value(ruby_obj)
        elsif ruby_obj.kind_of?(Float)
          memory.root_namespace["Float"].new_with_value(ruby_obj)
        elsif ruby_obj.kind_of?(BigDecimal)
          memory.root_namespace["Integer"].new_with_value(ruby_obj.to_i)
        elsif ruby_obj.kind_of?(Proc)
          memory.root_namespace["Lambda"].new_with_value(ESProc.new(ruby_obj, engine))
        elsif ruby_obj.kind_of?(RubyLambda)
          ruby_obj.es_lambda
        elsif ruby_obj.nil?
          memory.root_namespace["nil"]
        elsif ruby_obj == true
          memory.root_namesapce["true"]
        elsif ruby_obj == false
          memory.root_namesapce["false"]
        else
          RubyToEleetWrapper.new(ruby_obj, engine)
        end
      end

      def to_ruby_value(eleet_obj, engine)
        ruby_values = ["TrueClass", "FalseClass", "NilClass", "String", "Integer", "Float"]
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