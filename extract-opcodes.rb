# extract the opcodes from the listing file

start = /\<_stext\>:/
ended = /\<endmain\>:/

started = false
next_addr = nil

if ARGV.empty?
	puts "Requires listing filename"
	exit 1
end

# Read the input file
file = File.open(ARGV[0], "r")

# Loop through each line in the file
file.each_line do |line|
	if not started
		if line =~ start
			started= true
		end
		next
	else
		if line =~ ended
			started= false
			break
		end
	end

	# finds the address
	addr = line.match("^[0-9a-f]+:")
	# If address is found, extract the reset
	unless addr.nil?
		a = addr[0].to_i(16)
		if next_addr.nil?
			next_addr = a
		else
			if a != next_addr
				raise "address not consecutive @ #{a.to_s(16)} - #{next_addr.to_s(16)}"
			end
		end

		parts = line.split(" ")
		b_value = parts[1].gsub(/[^0-9a-f]/i, "")  # remove non-hex characters from the B value
		code = parts[2..-1].join(' ')
		# puts "Addr: #{addr[0]}, Extracted: #{b_value}, #{code}"

		if b_value.size > 4
			store = ','
			next_addr += 4
		else
			store = 'h,'
			next_addr += 2
		end
		puts "$#{b_value} #{store} \\ #{code}"
	end
end

# Close the file
file.close()
