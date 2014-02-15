class Regex
  to_string do
    pat = pattern
    flgs = flags
    "r\"%pat\"%flgs"
  end

  =~ do |str|
    str =~ self
  end
end