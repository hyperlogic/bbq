# rakefile

require 'rake/clean'

$verbose = true

CLEAN.include ['level.h', 'bbq.o', 'test.o']
CLOBBER.include ['test', 'level.bin']

$compile_flags = ['-Wall', '-g']
$link_flags = []

def shell cmd
  puts cmd if $verbose
  result = `#{cmd} 2>&1`
  result.each {|line| print line}
end

def compile obj, src
  puts "    Compiling #{obj}"
  cmd = "g++ #{$compile_flags.join " "} -c #{src} -o #{obj}"
  shell cmd
end

def link exe, objects
  puts "    Linking #{exe}"
  cmd = "g++ #{objects.join " "} -o #{exe} #{$link_flags.join " "}"
  shell cmd
end

# generate binary blob
file 'level.bin' => ['bbq.rb', 'bbq-cook', 'level.dd', 'level.di'] do
  puts '    Generating level.bin'
  shell 'bbq-cook level.di level.bin'
end

# generate header
file 'level.h' => ['bbq.rb', 'bbq-burn', 'level.dd'] do
  puts '    Generating level.h'
  shell 'bbq-burn level.dd level.h'
end

file 'bbq.o' => ['bbq.h', 'bbq.cpp'] do
  compile 'bbq.o', 'bbq.cpp'
end

file 'test.o' => ['bbq.h', 'level.h', 'test.cpp'] do
  compile 'test.o', 'test.cpp'
end

file 'test' => ['bbq.o', 'test.o'] do
  link 'test', ['bbq.o', 'test.o']
end

task :default => ['test', 'level.bin'] do
end
