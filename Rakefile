# Rakefile
SRC_DIR = 'src'
BUILD_DIR = 'build'
PROG = 'main'
TOOLSDIR = '/home/morris/Stuff/riscv/corev-openhw-gcc-ubuntu2204-20240530/bin'
ASSEMBLER = "#{TOOLSDIR}/riscv32-corev-elf-as"
LINKER = "#{TOOLSDIR}/riscv32-corev-elf-ld"
OBJDUMP = "#{TOOLSDIR}/riscv32-corev-elf-objdump"
ASFLAGS = '-g -march=rv32ima_zicsr_zifencei_zba_zbb_zbs_zbkb_zca_zcb_zcmp -mabi=ilp32'
LDFLAGS = '-g -m elf32lriscv -T linker-ram.ld'

# Collect all .s files in SRC_DIR
assembly_files = FileList["#{SRC_DIR}/*.s"]
object_files = assembly_files.ext('.o').pathmap("#{BUILD_DIR}/%f")

directory BUILD_DIR

rule '.o' => proc { |t|
  src = t.sub(/^#{BUILD_DIR}\//, "#{SRC_DIR}/").sub(/\.o$/, '.s')
  src
} do |t|
  sh "#{ASSEMBLER} #{ASFLAGS} -o #{t.name} #{t.source}"
end

file PROG => object_files do
  sh "#{LINKER} #{LDFLAGS} -o #{PROG}.elf #{object_files.join(' ')}"
end

task default: [PROG]

task :clean do
  rm_f object_files + [PROG]
end

task :disasm do
	sh "#{OBJDUMP} -d #{PROG}.elf > #{PROG}.lst"
end


task :probe do
	sh "xterm -e ./run-picoprobe &"
end

task :gdb do
	sh "xterm -e ./run-picoprobe &"
	sh "#{TOOLSDIR}/riscv32-corev-elf-gdb -x gdb.cfg #{PROG}.elf"
	sh "pkill openocd"
end
