# Rakefile

verbose(false)

SRC_DIR = 'src'
BUILD_DIR = 'build'
PROG = 'main'
TOOLSDIR = '/home/morris/Stuff/riscv/corev-openhw-gcc-ubuntu2204-20240530/bin'
ASSEMBLER = "#{TOOLSDIR}/riscv32-corev-elf-as"
LINKER = "#{TOOLSDIR}/riscv32-corev-elf-ld"
OBJDUMP = "#{TOOLSDIR}/riscv32-corev-elf-objdump"
ASFLAGS = '-g -march=rv32ima_zicsr_zifencei_zba_zbb_zbs_zbkb_zca_zcb_zcmp -mabi=ilp32'

# comment the following line and uncomment the next line to compile for FLASH
LDFLAGS = '-g -m elf32lriscv -T linker-ram.ld'
#LDFLAGS = '-g -m elf32lriscv -T linker-flash.ld'

# Collect all .s files in SRC_DIR
assembly_files = FileList["#{SRC_DIR}/*.s"]
object_files = assembly_files.ext('.o').pathmap("#{BUILD_DIR}/%f")

directory BUILD_DIR

rule '.o' => proc { |t|
  src = t.sub(/^#{BUILD_DIR}\//, "#{SRC_DIR}/").sub(/\.o$/, '.s')
  File.absolute_path(src)
} do |t|
  puts "Assembling #{t.source}"
  sh "#{ASSEMBLER} #{ASFLAGS} -o #{t.name} #{t.source}"
end

file "#{PROG}.elf" => object_files do |t|
  puts "Linking #{t.name} to RAM"
  sh "#{LINKER} #{LDFLAGS} --print-memory-usage -o #{t.name} #{object_files.join(' ')}"
end

task default: ["#{PROG}.elf"]

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
