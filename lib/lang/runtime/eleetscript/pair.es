class Pair
  property key value
  init do |@key, @value| end

  clone do
    Pair.new(@key.clone, @value.clone)
  end

  to_string do
    key = @key.inspect
    value = @value.inspect
    "%key => %value"
  end
end
