$:.unshift File.expand_path("../lib", __FILE__)
require 'hiera/backend/psql_version'

Gem::Specification.new do |s|
  s.version = HieraBackends::MongoDB::VERSION
  s.name = "hiera-mongodb"
  s.email = "courtoma@gmail.com"
  s.authors = "Marc-Andre Courtois"
  s.summary = "A MongoDB backend for Hiera."
  s.description = "Allows hiera functions to pull data from a MongoDB database."
  s.has_rdoc = false
  s.homepage = "http://github.com/mcourtois/hiera-mongodb"
  s.license = "Apache 2.0"
  s.files = Dir["lib/**/*.rb"]
  s.files += ["LICENSE"]

  s.add_dependency 'hiera', '~> 1.0'
  s.add_dependency 'mongo', '~> 1.8.5'
  s.add_dependency 'json', '~> 1.7'

  s.add_development_dependency 'rspec', '2.13'

end
