class Number
  >= do |val|
    self > val or self is val
  end

  <= do |val|
    self < val or self is val
  end
end