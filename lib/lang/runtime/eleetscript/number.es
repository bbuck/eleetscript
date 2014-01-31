class Number
  isnt do |val|
    not self is val
  end

  >= do |val|
    self > val or self is val
  end

  <= do |val|
    self < val or self is val
  end
end