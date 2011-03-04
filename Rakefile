require 'rake/gempackagetask'
spec = Gem::Specification.new do |s|
  s.name = 'bbq'
  s.summary = 'A data cooking tool which uses DSLs to generate C headers & binary data files'
  s.description = File.read(File.join(File.dirname(__FILE__), 'README'))
  s.requirements = [ 'TODO: not sure' ]
  s.version = '0.0.3'
  s.author = 'Anthony Thibault'
  s.email = 'ajt@hyperlogic.org'
  s.homepage = 'http://github.com/hyperlogic/bbq'
  s.platform = Gem::Platform::RUBY
  s.required_ruby_version = '>=1.8.7'
  s.files = Dir['bin/*', 'lib/*', 'lib/bbq/*', 'src/*', 'README']
  s.executables = ['bbq-burn', 'bbq-cook']
  s.has_rdoc = false
end
Rake::GemPackageTask.new(spec).define

# figure out the build platform
case `uname`.chomp
when /mingw32.*/i
  $PLATFORM = :windows
when "Darwin"
  $PLATFORM = :darwin
when "Linux"
  $PLATFORM = :linux
else
  $PLATFORM = :unknown
end

desc "rebuild gem and install"
task :install => :repackage do
  gem_command = $PLATFORM = :windows ? "gem" : "sudo gem"
  installed_gems = `gem list`
  if installed_gems =~ /bbq/
    sh "#{gem_command} uninstall bbq -x"
  end
  sh "#{gem_command} install #{Dir["pkg/*"][0]}"
end

