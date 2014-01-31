class List
  > do
    shift
  end

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

  each do |iter|
    if lambda? and iter.kind_of?(Lambda)
      keys = self.keys
      i = 0
      while i < keys.length
        key = keys[i]
        iter.call(self[key], key)
        i += 1
      end
    end
  end

  inject do |val, iter|
    if lambda? and iter.kind_of?(Lambda)
      self.each -> { |item, key|
        val = iter.call(val, item, key)
      }
    end
    val
  end

  sum do
    inject(0) -> { |sum, val|
      if val.kind_of?(Number)
        sum + val
      else
        sum
      end
    }
  end
end