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

  @@println do |msg|
    IO.println(msg)
  end

  @@print do |msg|
    IO.print(msg)
  end

  to_string do
    class_name
  end

  println do |msg|
    IO.println(msg)
  end

  print do |msg|
    IO.print(msg)
  end

  inspect do
    to_string
  end

  no_method do
    nil
  end

  __negate! do
    self
  end
end