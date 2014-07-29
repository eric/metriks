Gem::Specification.new do |s|
  s.name              = 'metriks'
  s.version           = '0.9.9.6'
  s.date              = '2014-02-24'

  s.summary     = "An experimental metrics client"
  s.description = "An experimental metrics client."

  s.authors  = ["Eric Lindvall"]
  s.email    = 'eric@sevenscale.com'
  s.homepage = 'https://github.com/eric/metriks'

  s.licence = 'MIT'

  s.rdoc_options = ["--charset=UTF-8"]
  s.extra_rdoc_files = %w[README.md LICENSE]

  s.add_dependency('atomic', ["~> 1.0"])
  s.add_dependency('hitimes', [ "~> 1.1"])

  s.add_development_dependency('mocha', ['~> 0.10'])

  s.files = Dir['LICENSE', 'README.md', 'lib/**/*']
  s.require_paths = %w[lib]
end
