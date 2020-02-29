$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "rapid_resources/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "rapid_resources"
  s.version     = RapidResources::VERSION
  s.authors     = ["Martins Polakovs"]
  s.email       = ["martins.polakovs@gmail.com"]
  s.homepage    = "http://localhost"
  s.summary     = "Simplifies app building"
  s.description = "Simplifies app building"
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

  s.add_dependency "rails", ">= 5.1"
end
