module EleetScript
  class EleetScriptMethod
    def initialize(params, body, block = nil)
      @params = params
      @body = body
      @block = block
    end

    def call(receiver, arguments, memory)
      context = Context.new(receiver)

      @params.each_with_index do |param, index|
        arg = arguments[index]
        if param.start_with? "@@"
          name = param[2..-1]
          context.current_class.class_vars[name] = arg
        elsif param.start_with?("@") && context.current_self.instance?
          name = param[1..-1]
          context.current_self.instance_vars[name] = arg
        else
          context.locals[param] = arg
        end
      end

      context.locals["arguments"] = memory.constants["List"].call(:new, arguments)

      @body.eval(context, context.current_class.memory)
    end
  end
end