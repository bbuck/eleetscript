module EleetScript
  Memory.define_core_methods do
    nil_cls = root_namespace["NilClass"]

    nil_cls.def :clone do |receiver, arguments|
      root_namespace["nil"]
    end
  end
end