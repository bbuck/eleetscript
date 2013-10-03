class List
  < do |value|
    self.push(value)
  end

  + do |other|
    if other.kind_of?(List)
      self.merge!(other)
    else
      self
    end
  end
end