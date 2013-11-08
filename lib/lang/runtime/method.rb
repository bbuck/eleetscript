module EleetScript
  class EleetScriptMethod
    def initialize(params, body, block = nil)
      @params = params
      @body = body
      @block = block
    end

    def call(receiver, arguments, parent_context)
      context = parent_context.new_method_context

      @params.each_with_index do |param, index|
        arg = arguments[index]
        context[param] = arg
      end

      context["arguments"] = context["List"].call(:new, arguments)

      @body.eval(context)
    end

    def arity
      3
    end
  end
end