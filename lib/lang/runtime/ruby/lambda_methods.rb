module EleetScript
  Memory.define_core_methods do
    lambda = root_namespace["Lambda"]

    lambda.def :call do |receiver, arguments, context|
      receiver.ruby_value.call(nil, arguments, context)
    end

    lambda.def :apply do |receiver, arguments, context|
      args = arguments.first
      args = if args.is_a?("List")
        arg_list = args.ruby_value.array_value.dup
        arg_list + args.ruby_value.hash_value.map do |k, v|
          root_namespace["Pair"].call(:new, [k, v])
        end
      else
        []
      end
      receiver.ruby_value.call(nil, args, context)
    end
  end
end
