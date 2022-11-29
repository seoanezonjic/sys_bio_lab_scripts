#!/usr/bin/env ruby
#El manejo de los headers es un poco cancer, rehacer
require 'optparse'

#########################################################################
## => METHODS
#########################################################################

def load_and_index(input_file, i_col, header)
	i_file = {}
	File.open(input_file).each_with_index do |line, line_index|
		line = line.chomp.split("\t")
		row_index = line[i_col]
		line.delete_at(i_col)
		if header && line_index == 0
			i_file["header"] = {row_index => line}
		else
			i_file[row_index] = [] if i_file[row_index].nil?
			i_file[row_index] << line
		end
	end	
	return(i_file)
end


def merge_and_write(file_A,file_B, output_file, header)
	File.open(output_file, 'w') do |o_file|
		file_A.each do |indexed_col, rows|
			if indexed_col == "header"
				o_file.puts [rows.first[0], rows.first[1], file_B["header"].first[1]].flatten.join("\t")
				next	
			end
			rows.each do |row|
				next if file_B[indexed_col].nil?
				file_B[indexed_col].each do |row_to_merge|
					o_file.puts [indexed_col, row, row_to_merge].flatten.join("\t")
				end
			end
		end
	end
end
#########################################################################
## => OPTIONS
#########################################################################


options = {}

OptionParser.new do |opts|

	options[:input_files] = nil
	opts.on("-i FILE_A,FILE_B", "--input_files FILE_A,FILE_B", "Define, separated by comma , files to merge.") do |files|
		options[:input_files] = files.split(",")
	end


	options[:indexes] = [1,1]
	opts.on("-I index_a,index_b", "--indexes index_a,index_b", "Define, separated by comma ,column numbers to use as index 'index_a,index_b'.") do |str|
		options[:indexes] = str.split(",").map(&:to_i)
	end
	
	options[:header] = false
	opts.on("-H", "--header", "Set if both files have header. Index columns must have the same name") do 
		options[:header] = true
	end

	options[:output_file] = nil
	opts.on("-o FILE", "--output_file FILE", "Define output file.") do |file|
		options[:output_file] = file
	end

	opts.on("-h", "--help", "Displays helps") do 
		puts opts
		exit
	end

end.parse!

#########################################################################
## => MAIN
#########################################################################

file_A = load_and_index(options[:input_files][0], options[:indexes][0], options[:header])
file_B = load_and_index(options[:input_files][1], options[:indexes][1], options[:header])
merge_and_write(file_A,file_B, options[:output_file], options[:header])