module EleetScript
  Memory.define_core_methods do
    true_cls = root_namespace["TrueClass"]
    false_cls = root_namespace["FalseClass"]

    true_cls.def :clone do |receiver, arguments|
      root_namespace["true"]
    end

    false_cls.def :clone do |receiver, arguments|
      root_namespace["false"]
    end
  end
end