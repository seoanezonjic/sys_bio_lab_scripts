#! /usr/bin/env ruby

####################################
## MAIN
####################################
path = ARGV[0]

if path =='-'
	source = STDIN
else
	source = File.open(path)
end

counts = {}
header = nil
count = 0
source.each do |line|
	line.chomp!
	if count == 0
		header = line
	else
		fields = line.split("\t")
		id = fields.shift.gsub(/\.\d+/,'')
		fields.map!{|f| f.to_i}
		query = counts[id]
		if query.nil?
			counts[id] = fields
		else
			query.each_with_index do |count, i|
				query[i] = count + fields[i]
			end
		end
	end
	count += 1
end

puts header
counts.each do |id, counts|
	puts "#{id}\t#{counts.join("\t")}"
end
