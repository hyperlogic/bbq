spec = Gem::Specification.new do |s|
  s.name = 'ajtbbq'
  s.summary = 'A data cooking tool which uses DSLs to generate C headers & binary data files'
  s.description = File.read(File.join(File.dirname(__FILE__), 'README'))
  s.version = '0.0.4'
  s.author = 'Anthony Thibault'
  s.email = 'ajt@hyperlogic.org'
  s.homepage = 'http://github.com/hyperlogic/bbq'
  s.platform = Gem::Platform::RUBY
  s.required_ruby_version = '>=1.8.7'
  s.files = Dir['bin/*', 'lib/*', 'lib/bbq/*', 'src/*', 'README']
  s.executables = ['bbq-burn', 'bbq-cook']
  s.license = 'MIT'
  s.has_rdoc = false
end

