module EleetScript
  Memory.define_core_methods do
    true_cls = root_namespace["TrueClass"]
    false_cls = root_namespace["FalseClass"]

    true_cls.def :clone do |receiver, arguments|
      true_cls.new_with_value(true)
    end

    false_cls.def :clone do |receiver, arguments|
      false_cls.new_with_value(false)
    end
  end
end