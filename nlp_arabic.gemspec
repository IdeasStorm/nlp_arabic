$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "nlp_arabic/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "nlp_arabic"
  s.version     = NlpArabic::VERSION
  s.authors     = ["mhdsyrwan", "yamanaltereh", "mhdaljobory"]
  s.email       = ["mhdsyrwan@gmail.com","mhdaljobory@gmail.com", "yamman05@gmail.com"]
  s.homepage    = "http://ideasstorm.net/nlp_arabic"
  s.summary     = "A simple arabic sentences matching tools built on khoja algorithm & awn db"
  s.description = "Arabic Language processing tools"

  s.files = Dir["{app,config,db,lib}/**/*"] + ["MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency "rails", "~> 3.2.13"

  s.add_development_dependency "sqlite3"
end
