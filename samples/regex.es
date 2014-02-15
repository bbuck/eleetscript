rx = r"my name is (.+)"i
str = "My name is Brandon"

if str =~ rx # or str.match?(rx)
  matches = str.match(rx)
  # matches is a list of all matches, match[0] is the full match and indexes/keys
  # are matched groups - in this case matches[1] is equal to group 1.
  name = matches[1]
  println("Your name is %name")
end

rx = r"my name is (?<name>.+)"i
if str =~ rx
  matches = str.match(rx)
  # Named groups are accessed by their names
  name = matches["name"]
  println("Your name is %name")
end