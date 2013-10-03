class Pair
  property key value
  init do |@key, @value| end

  clone do
    Pair.new(@key.clone, @value.clone)
  end

  to_string do
    "<Pair " + @key.inspect + " => " + @value.inspect + ">"
  end
end