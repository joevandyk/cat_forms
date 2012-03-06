# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "cat_forms/version"

Gem::Specification.new do |s|
  s.name        = "cat_forms"
  s.version     = CatForms::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Joe Van Dyk"]
  s.email       = ["joe@tanga.com"]
  s.homepage    = "https://github.com/joevandyk/cat_forms"
  s.summary     = %q{Helps make complex forms}
  s.description = %q{Helps make complex forms}
  s.rubyforge_project = "cat_forms"

  s.add_dependency('activemodel')
  s.add_dependency('virtus')

  s.add_development_dependency 'minitest'
  s.add_development_dependency 'rake'

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
