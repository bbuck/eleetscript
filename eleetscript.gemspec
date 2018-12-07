require "lib/eleetscript"

Gem::Specification.new do |s|
  s.name = "eleetscript"
  s.version = EleetScript::VERSION
  s.license = "MIT"
  s.date = "2018-12-07"
  s.summary = "EleetScript Engine"
  s.description = "EleetScript scripting engine for use in Ruby applications"
  s.authors = ["Brandon Buck"]
  s.email = "lordizuriel@gmail.com"
  s.files = Dir.glob("lib/**/*")
  s.homepage = "http://github.com/bbuck/eleetscript"
  s.executables << "eleet"
end
