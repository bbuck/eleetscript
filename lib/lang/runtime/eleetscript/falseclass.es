class FalseClass
  @@new do 
    false
  end

  not do
    true
  end

  and do
    false
  end

  or do |o|
    if o
      o
    else
      false
    end
  end

  to_string do
    "false"
  end
end
