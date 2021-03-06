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
  result.each_line {|line| print line}
end

def compile obj, src
  puts "    Compiling #{obj}"
  cmd = "g++ #{$compile_flags.join " "} -c #{src} -o #{obj}"
  shell cmd
end

def link_exe exe, objects
  puts "    Linking #{exe}"
  cmd = "g++ #{objects.join " "} -o #{exe} #{$link_flags.join " "}"
  shell cmd
end

# generate binary blob
file 'level.bin' => ['level.dd', 'level.di'] do
  puts '    Generating level.bin'
  shell 'bbq-cook -l level.di level.bin'
end

# generate header
file 'level.h' => ['level.dd'] do
  puts '    Generating level.h'
  shell 'bbq-burn -n bbq level.dd level.h'
end

file 'bbq.o' => ['bbq.h', 'bbq.c'] do
  compile 'bbq.o', 'bbq.c'
end

file 'test.o' => ['bbq.h', 'level.h', 'test.cpp'] do
  compile 'test.o', 'test.cpp'
end

file 'test' => ['bbq.o', 'test.o'] do
  link_exe 'test', ['bbq.o', 'test.o']
end

task :default => ['test', 'level.bin'] do
end
