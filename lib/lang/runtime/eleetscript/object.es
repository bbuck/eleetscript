class Object
  @@kind_of? do
    no
  end

  @@no_method do
    nil
  end

  @@inspect do
    class_name
  end

  to_string do
    class_name
  end

  inspect do
    to_string
  end

  __nil_method do
    nil
  end

  no_method do
    nil
  end

  __negate! do
    self
  end
end