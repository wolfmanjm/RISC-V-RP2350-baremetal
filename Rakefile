# Rakefile

verbose(ENV['verbose'] == '1')
if ENV['flash']
	FLASHBUILD = true
else
	FLASHBUILD = false
end

if ENV['target'].nil?
	PROG = 'main'
else
	PROG = ENV['target']
end

TESTS = ENV['notests'].nil?

SRC_DIR = 'src'
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

# Collect all .s files in SRC_DIR
assembly_files = FileList["#{SRC_DIR}/*.s"]
object_files = assembly_files.ext('.o').pathmap("#{BUILD_DIR}/%f")

# files that should go into the library
LIBRARY_FILES = [
"adc",
"div64",
"fixpt",
"gpio",
"i2c",
"ili9341",
"imu",
"multicore",
"neopixel",
"pwm",
"rotary",
"spi",
"startup",
"ticks",
"timer",
"uart",
]

LIB_OBJS = (LIBRARY_FILES).collect { |d| "#{BUILD_DIR}/#{d}.o" }

directory BUILD_DIR

defines = ""
defines = "--defsym TESTS=1" if TESTS

rule '.o' => proc { |t|
  src = t.sub(/^#{BUILD_DIR}\//, "#{SRC_DIR}/").sub(/\.o$/, '.s')
  File.absolute_path(src)
} do |t|
  puts "Assembling #{t.source}"
  # add --defsym COPYTORAM=1 if flash text is to be copied to RAM
  sh "#{ASSEMBLER} #{ASFLAGS} #{defines} -o #{t.name} #{t.source}"
end

file "#{PROG}.elf" => object_files do |t|
  puts "Linking #{t.name} to #{FLASHBUILD ? 'FLASH' : 'RAM'}"
  sh "#{LINKER} #{LDFLAGS} --print-memory-usage -o #{t.name} #{object_files.join(' ')}"
end

file "#{PROG}.uf2" => "#{PROG}.elf" do |t|
  puts "Creating #{t.name}"
  sh "#{PICOTOOL} uf2 convert #{t.source} #{t.name} --family rp2350-riscv"
end

file "libhal.a" => LIB_OBJS do |t|
  puts "Creating #{t.name}"
  sh "#{AR} #{ARFLAGS} libhal.a #{t.sources.join(' ')}"
end

if FLASHBUILD
  task :default => ["#{PROG}.uf2"]
else
  task :default => ["#{PROG}.elf"]
end

task :notests do
	defines = ""
end

# to use the libhal.a ...
# ${LINKER} #{LDFLAGS} build/testmain.o -L. -lhal
task :mklib => [:clean, :notests, "libhal.a"]

task :clean do
  rm_f object_files + ["#{PROG}.elf", "#{PROG}.lst"]
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
