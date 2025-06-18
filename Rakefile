# Rakefile

verbose(ENV['verbose'] == '1')
if ENV['flash']
	FLASHBUILD = true
else
	FLASHBUILD = false
end

if ENV['target'].nil?
	PROG = 'testmain'
else
	PROG = ENV['target']
end

APP_SRC = 'appsrc'
LIB_DIR = 'libsrc'
BUILD_DIR = 'build'
TOOLSDIR = '/home/morris/Stuff/riscv/corev-openhw-gcc-ubuntu2204-20240530/bin'
ASSEMBLER = "#{TOOLSDIR}/riscv32-corev-elf-as"
LINKER = "#{TOOLSDIR}/riscv32-corev-elf-ld"
OBJDUMP = "#{TOOLSDIR}/riscv32-corev-elf-objdump"
ASFLAGS = '-g -march=rv32ima_zicsr_zifencei_zba_zbb_zbs_zbkb_zca_zcb_zcmp -mabi=ilp32'
AR = "#{TOOLSDIR}/riscv32-corev-elf-ar"
ARFLAGS = 'r'
PICOTOOL = '/home/morris/Stuff/rpipico/picotool/bin/picotool/picotool'

if FLASHBUILD
	LDFLAGS = '-g -m elf32lriscv -T linker-flash.ld'
else
	LDFLAGS = '-g -m elf32lriscv -T linker-ram.ld'
end

mkdir_p(BUILD_DIR)
directory BUILD_DIR

# files that should go into the library
LIBRARY_SRC = FileList["#{LIB_DIR}/*.s"]
LIBRARY_OBJECTS = LIBRARY_SRC.ext('.o').pathmap("#{BUILD_DIR}/%f")

defines = ""

# building the app
file "#{BUILD_DIR}/#{PROG}.o" => ["#{APP_SRC}/#{PROG}.s"] do |t|
  puts "Assembling App #{t.source}"
  src = File.absolute_path(t.source)
  sh "#{ASSEMBLER} #{ASFLAGS} #{defines} -o #{t.name} #{src}"
end

file "libhal.a" => LIBRARY_OBJECTS do |t|
  puts "Creating #{t.name}"
  sh "#{AR} #{ARFLAGS} libhal.a #{t.sources.join(' ')}"
end

file "#{PROG}.elf" => ['libhal.a', "#{BUILD_DIR}/#{PROG}.o"] do |t|
  puts "Linking #{t.name} to #{FLASHBUILD ? 'FLASH' : 'RAM'}"
  sh "#{LINKER} #{LDFLAGS} --print-memory-usage -o #{t.name} #{BUILD_DIR}/#{PROG}.o -L. -lhal"
end

file "#{PROG}.uf2" => "#{PROG}.elf" do |t|
  puts "Creating #{t.name}"
  sh "#{PICOTOOL} uf2 convert #{t.source} #{t.name} --family rp2350-riscv"
end


if FLASHBUILD
  task :default => ["#{PROG}.uf2"]
else
  task :default => ["#{PROG}.elf"]
end

task :mklib => [:clean, "libhal.a"]

task :clean do
  rm_f ["build/*", "#{PROG}.elf", "#{PROG}.lst", "libhal.a"]
end

task :disasm do
	sh "#{OBJDUMP} -d #{PROG}.elf > #{PROG}.lst"
end

task :probe do
	sh "xterm -geometry 140x62+1800+0 -e ./run-picoprobe &"
end

task :gdb do
	sh "xterm -e ./run-picoprobe &"
	sh "#{TOOLSDIR}/riscv32-corev-elf-gdb -x gdb.cfg #{PROG}.elf"
	sh "pkill openocd"
end

# building the library sources, or any .o that is not explicitly called out above
# however NOTE that the source need to be in the libsrc directory
rule '.o' => proc { |t|
  src = t.sub(/^#{BUILD_DIR}\//, "#{LIB_DIR}/").sub(/\.o$/, '.s')
  File.absolute_path(src)
} do |t|
  puts "Assembling #{t.source}"
  # add --defsym COPYTORAM=1 if flash text is to be copied to RAM
  sh "#{ASSEMBLER} #{ASFLAGS} #{defines} -o #{t.name} #{t.source}"
end

