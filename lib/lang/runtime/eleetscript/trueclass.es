class TrueClass
  @@new do
    true
  end

  not do
    false
  end

  and do |o|
    if o is true
      o
    else
      false
    end
  end

  or do
    true
  end

  to_string do
    "true"
  end
end
