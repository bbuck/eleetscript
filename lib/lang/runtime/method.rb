module EleetScript
  class EleetScriptMethod
    def initialize(params, body, lambda_context = nil)
      @params = params
      @body = body
      @lambda_context = lambda_context
    end

    def call(receiver, arguments, parent_context)
      context = parent_context.new_method_context(@lambda_context)

      context["lambda?"] = context["false"]
      @params.each_with_index do |param, index|
        arg = arguments[index]
        next unless arg
        context[param] = arg
        if arg.is_a?("Lambda")
          context["lambda?"] = context["true"]
        end
      end

      context["arguments"] = context["List"].call(:new, arguments)

      @body.eval(context)
    end

    def arity
      3
    end
  end
end