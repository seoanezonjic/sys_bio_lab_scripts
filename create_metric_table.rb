#!/usr/bin/env ruby

metric_file = ARGV[0]
fixCols = ARGV[1].split(',')
output = ARGV[2]
name_tag = fixCols.shift
fixColNumber = fixCols.length

hash = {}

varTags = []
File.open(ARGV[0]).each do |line|
	line.chomp!
	fields = line.split("\t")
	name = fields.shift
	fixFields = fields[0..fixColNumber-1]
	varFields = fields[fixColNumber..fixColNumber+1]
	varTags << varFields.first if !varTags.include?(varFields.first)

	query = hash[name]
	if query.nil?
		hash[name] = {varFields.first => varFields.last}
		fixCols.each_with_index do |tag, i|
			hash[name][tag] = fixFields[i] 
		end
	else
		query[varFields.first] = varFields.last
	end
end


metric_table = File.new(output, "w")
if fixColNumber > 0
	header="#{name_tag}\t#{fixCols.join("\t")}\t#{varTags.join("\t")}"
else
	header="#{name_tag}\t#{varTags.join("\t")}"
end

metric_table.puts(header)
allTags = fixCols.concat(varTags)
hash.each do |name, fields|
 	array_temp = [name]
 	allTags.each do |tag|
 		array_temp << fields[tag]
 	end
 	metric_table.puts(array_temp.join("\t"))
end
metric_table.close()


