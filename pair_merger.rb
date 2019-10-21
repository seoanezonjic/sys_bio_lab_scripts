#! /usr/bin/env ruby

require 'optparse'
##########################################################################################
## METHODS
##########################################################################################
def load_pair_files(file, index_col_number, node_col_number)
	pairs = {}
	File.open(file).each do |line|
		line.chomp!
		fields = line.split("\t")
		index = fields[index_col_number]
		node = fields[node_col_number]
		query = pairs[index]
		if query.nil?
			pairs[index] = [node]
		else
			query << node
		end
	end
	return pairs
end

##########################################################################################
## OPTPARSE
##########################################################################################

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: #{__FILE__} [options]"

  options[:a_file] = nil
  opts.on("-a", "--a_file PATH", "First file with pairs") do |file|
    options[:a_file] = file
  end

  options[:a_index_col_number] = nil
  opts.on("-A", "--a_index_col_number INTEGER", "For first file, the column number (1 based) of the field to use as index") do |col|
    options[:a_index_col_number] = col.to_i - 1
  end

  options[:a_node_col_number] = nil
  opts.on("-x", "--a_node_col_number INTEGER", "For first file, the column number (1 based) of the field with node ids") do |col|
    options[:a_node_col_number] = col.to_i - 1
  end

  options[:b_file] = nil
  opts.on("-b", "--b_file PATH", "Second file with pairs") do |file|
    options[:b_file] = file
  end

  options[:b_index_col_number] = nil
  opts.on("-B", "--b_index_col_number INTEGER", "For second file, the column number (1 based) of the field to use as index") do |col|
    options[:b_index_col_number] = col.to_i - 1
  end

  options[:b_node_col_number] = nil
  opts.on("-y", "--b_node_col_number INTEGER", "For second file, the column number (1 based) of the with node ids") do |col|
    options[:b_node_col_number] = col.to_i - 1
  end

end.parse!

##########################################################################################
## MAIN
##########################################################################################

a_pairs = load_pair_files(options[:a_file], options[:a_index_col_number], options[:a_node_col_number])
b_pairs = load_pair_files(options[:b_file], options[:b_index_col_number], options[:b_node_col_number])

a_pairs.each do |a_tag, a_cluster|
	a_length = a_cluster.length
	b_pairs.each do |b_tag, b_cluster|
		intersection_length = (a_cluster & b_cluster).length
		if intersection_length >= a_length
			puts "#{a_tag}\t#{b_tag}"
		end
	end
end
