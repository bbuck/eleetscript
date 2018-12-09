# frozen_string_literal: true

module EleetScript
  Memory.define_core_methods do
    enum = root_namespace['Enumerable']

    enum.def :to_list do |receiver, arguments, context|
      root_namespace['List'].new_with_value(receiver.ruby_value, context)
    end
  end
end
