# frozen_string_literal: false

module EleetScript
  class EleetScriptMethod
    def initialize(name, params, body, lambda_context = nil)
      @name = name
      @params = params
      @body = body
      @lambda_context = lambda_context
    end

    def call(receiver, arguments, parent_context)
      context = parent_context.new_method_context(@name, @lambda_context)

      context['lambda?'] = context['false']
      @params.each_with_index do |param, index|
        arg = arguments[index]
        next unless arg
        context[param] = arg
      end
      if arguments.length > 0 && arguments.last.is_a?('Lambda')
        context['lambda?'] = context['true']
        context['lambda'] = arguments.last
      end

      context['arguments'] = context['List'].call(:new, arguments)

      @body.eval(context)
    end

    def arity
      3
    end
  end
end
