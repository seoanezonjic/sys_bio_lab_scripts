#!/usr/bin/env ruby

require 'optparse'

#########################################################################
## => METHODS
#########################################################################

def load_and_index(input_file, i_col)
	i_file = {}
	File.open(input_file).each do |line|
		line = line.chomp.split("\t")
		i_file[line[i_col]] = [] if i_file[line[i_col]].nil?
		i_file[line[i_col]] << line.delete_at(i_col)
	end	
	return(i_file)
end


def merge_and_write(file_A,file_B, output_file, keep_all)
	file_A.each do |indexed_col, rows|
		rows.each do |row|
			next if file_B[indexed_col].nil?
			file_B[indexed_col].each do |row_to_merge|
				File.open(output_file, 'w') do |o_file|
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
	opts.on("-i index_a,index_b", "--indexes index_a,index_b", "Define, separated by comma ,column numbers to use as index 'index_a,index_b'.") do |str|
		options[:indexes] = str.split(",").map(&:to_i)
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

file_A = load_and_index(options[:input_files][0], options[:indexes][0])
file_B = load_and_index(options[:input_files][1], options[:indexes][1])

merge_and_write(file_A,file_B, options[:output_file])
