#! /usr/bin/env ruby

parent_table = {}
table_length = 0

ARGV.each do |file_name|
	
	local_length = 0
	File.open(file_name).each do |line|
		line.chomp!
		n_fields = line.count("\t")+1
		fields = line.split("\t", n_fields).map{|field| 
			if field == ""
				'-'
			else
				field
			end
		}
		next if fields.count('-') == fields.length #skip blank records
		id = fields.shift 
		local_length = fields.length
		if !parent_table.has_key?(id)
			parent_table[id] = Array.new(table_length,'-')
		elsif parent_table[id].length < table_length
			parent_table[id].concat(Array.new(table_length-parent_table[id].length,'-'))
		end
		parent_table[id].concat(fields)

	end

	table_length += local_length
	parent_table.each do |id, fields|
		diference = table_length - fields.length
		fields.concat(Array.new(diference,'-')) if diference > 0
	end

end

parent_table.each do |id, fields|
	puts id+"\t"+fields.join("\t")
end
