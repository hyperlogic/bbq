require 'rake/gempackagetask'
spec = Gem::Specification.new do |s|
  s.name = 'bbq'
  s.summary = 'A data cooking tool which uses DSLs to generate C headers & binary data files'
  s.description = File.read(File.join(File.dirname(__FILE__), 'README'))
  s.requirements = [ 'TODO: not sure' ]
  s.version = '0.0.2'
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

def shell cmd
  puts cmd
  result = `#{cmd} 2>&1`
  result.each {|line| print line}
end

desc "rebuild gem and install"
task :install => :repackage do
  installed_gems = `gem list`
  if installed_gems =~ /bbq/
    shell 'sudo gem uninstall bbq -x'
  end
  shell "sudo gem install #{Dir["pkg/*"][0]}"
end

