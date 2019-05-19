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

desc "install gem, uninstalling previous if necessary"
task :install => :build do
  installed_gems = `gem list`
  if installed_gems =~ /ajtbbq/
    sh "gem uninstall ajtbbq -x"
  end
  sh "gem install ajtbbq"
end

desc "build gem file"
task :build => ['ajtbbq-0.0.4.gem'] do
  sh "gem build ajtbbq.gemspec"
end

task :default => :install
