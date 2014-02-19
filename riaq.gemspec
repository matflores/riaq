Gem::Specification.new do |s|
  s.name        = "riaq"
  s.version     = "0.0.1"
  s.summary     = "Riak based queues and workers, inspired by Ost."
  s.description = "Riaq lets you manage queues and workers with Riak."
  s.authors     = ["Matías Flores"]
  s.email       = ["flores.matias@gmail.com"]
  s.homepage    = "http://github.com/soveran/ost"
  s.license     = "MIT"

  s.files = Dir[
    "LICENSE",
    "README.md",
    "Rakefile",
    "lib/**/*.rb",
    "*.gemspec",
    "test/*.*"
  ]

  s.add_dependency "riak-client", "~> 1.4.3"
  s.add_development_dependency "protest", "~> 0.5.1"
end
