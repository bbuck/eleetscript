module EleetScript
  Memory.define_core_methods do
    object = root_namespace["Object"]

    object.class_def :new do |receiver, arguments, context|
      ins = receiver.new(context.namespace_context)
      ins.call("init", arguments)
      ins
    end

    object.def :kind_of? do |receiver, arguments|
      t, f = root_namespace["true"], root_namespace["false"]
      if arguments.length == 0 || !arguments.first.class?
        f
      else
        names = []
        names << receiver.runtime_class.name
        cur_class = receiver.runtime_class
        while root_namespace["Object"] != cur_class.super_class
          names << cur_class.super_class.name
          cur_class = cur_class.super_class
        end
        names << "Object" # Base of everything
        name = arguments.first.name
        names.include?(name) ? t : f
      end
    end

    object.def :class do |receiver, arguments|
      receiver.runtime_class
    end

    object.def :class_name do |receiver, arguments, context|
      root_namespace["String"].new_with_value(receiver.runtime_class.name, context.namespace_context)
    end

    object.class_def :class_name do |receiver, arguments, context|
      root_namespace["String"].new_with_value(receiver.name, context.namespace_context)
    end

    object.def :is do |receiver, arguments|
      if receiver == arguments.first
        root_namespace["true"]
      else
        root_namespace["false"]
      end
    end

    object.def :clone do |receiver, arguments, context|
      cls_name = receiver.runtime_class.name
      if ["Integer", "Float", "String", "List"].include?(cls_name)
        receiver.runtime_class.new_with_value(receiver.ruby_value.dup, context.namespace_context)
      else
        ins = receiver.runtime_class.call(:new)
        ins.ruby_value = receiver.ruby_value.dup
      end
    end
  end
end