# Rakefile

verbose(ENV['verbose'] == '1')
if ENV['flash']
	FLASHBUILD = true
else
	FLASHBUILD = false
end

SRC_DIR = 'src'
BUILD_DIR = 'build'
PROG = 'main'
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

LIB_OBJS = FileList["#{BUILD_DIR}/*.o"]

directory BUILD_DIR

rule '.o' => proc { |t|
  src = t.sub(/^#{BUILD_DIR}\//, "#{SRC_DIR}/").sub(/\.o$/, '.s')
  File.absolute_path(src)
} do |t|
  puts "Assembling #{t.source}"
  sh "#{ASSEMBLER} #{ASFLAGS} -o #{t.name} #{t.source}"
end

file "libhal.a" => LIB_OBJS do |t|
  puts "Creating #{t.name}"
  sh "#{AR} #{ARFLAGS} #{t.name} #{LIB_OBJS}"
end

file "#{PROG}.elf" => object_files do |t|
  puts "Linking #{t.name} to #{FLASHBUILD ? 'FLASH' : 'RAM'}"
  sh "#{LINKER} #{LDFLAGS} --print-memory-usage -o #{t.name} #{object_files.join(' ')}"
end

file "#{PROG}.uf2" => "#{PROG}.elf" do |t|
  puts "Creating #{t.name}"
  sh "#{PICOTOOL} uf2 convert #{t.source} #{t.name} --family rp2350-riscv"
end

if FLASHBUILD
  task default: ["#{PROG}.uf2"]
else
  task default: ["#{PROG}.elf"]
end

task lib: ["libhal.a"]

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
