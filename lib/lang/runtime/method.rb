module Cuby
  class Method
    def initialize(params, body)
      @params = params
      @body = body
    end

    def call(reciever, arguments)
      context = Context.new(reciever)

      @params.each_with_index do |param, index|
        if param.start_with? "@@"
          name = param[2..-1]
          context.current_class.class_vars[name] = arguments[index]
        elsif param.start_with? "@"
          name = param[1..-1]
          context.current_self.instance_vars[name] = arguments[index]
        else
          context.locals[param] = arguments[index]
        end
      end

      context.locals["arguments"] = arguments

      @body.eval(context, context.current_class.memory)
    end
  end
end