module EleetScript
  Memory.define_core_methods do
    nil_cls = root_namespace["NilClass"]

    nil_cls.def :clone do |receiver, arguments|
      nil_cls.new_with_value(nil)
    end
  end
end