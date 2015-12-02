class NilClass
  @@new do
    nil
  end

  to_string do
    "nil"
  end
end
