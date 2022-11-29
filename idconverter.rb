#! /usr/bin/env ruby

require 'optparse'

###############################################
## METHODS
##############################################
def load_file(path)
	data = []
	File.open(path).each do |line|
		data << line.chomp.split("\t")
	end
	return data
end

def load_dictionary(path)
	dict = {}
	File.open(path).each do |line|
		from, to = line.chomp.split("\t")
		query = dict[from]
		if query.nil?
			dict[from] = [to]
		else
			query << to
		end
	end
	return dict
end

def translate_data(input_data, dictionary, col_numbers, row_numbers, keep_header)
	new_data = []
	if !col_numbers.nil?
		new_data = translate_cols(input_data, dictionary, col_numbers, keep_header)
	elsif !row_numbers.nil?
		new_data = translate_rows(input_data, dictionary, row_numbers, keep_header)
	end
	return new_data
end

def translate_cols(input_data, dictionary, col_numbers, keep_header)
	new_data = []
	input_data.each_with_index do |record, i|
		valid_row = true
		col_numbers.each do |col_number|
			old_id = record[col_number]
			new_ids = dictionary[old_id]
			if !new_ids.nil?
				new_ids.each do |new_id|
					record[col_number] = new_id
				end
			elsif i == 0 && keep_header
				valid_row = true
			else 
				valid_row = false
			end
		end
		new_data << record if valid_row
	end
	return new_data
end

def translate_rows(input_data, dictionary, row_numbers, keep_header)
	new_data = translate_cols(input_data.transpose, dictionary, row_numbers, keep_header)
	return new_data.transpose
end

##########################################################################################
## OPTPARSE
##########################################################################################

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: #{__FILE__} [options]"

  options[:col_numbers] = nil
  opts.on("-c", "--col_numbers INT", "Translate given column ids. 0 based coordinates.") do |opt|
    options[:col_numbers] = opt.split(",").map!{|c| c.to_i}
  end

  options[:row_numbers] = nil
  opts.on("-r", "--row_numbers INT", "Translate given row ids. 0 based coordinates.") do |opt|
    options[:row_numbers] = opt.split(",").map!{|r| r.to_i}
  end

  options[:input_file] = nil
  opts.on("-i", "--input PATH", "Path to input file.") do |opt|
    options[:input_file] = opt
  end

  options[:dictionary_file] = nil
  opts.on("-d", "--dictionary_file PATH", "Path to input dictionary file. Two columns, original id and new id.") do |opt|
    options[:dictionary_file] = opt
  end

  options[:keep_header] = false
  opts.on("-k", "--keep_header", "Keep header") do |opt|
    options[:keep_header] = true
  end

end.parse!



##############################################
## MAIN
#############################################

input_data = load_file(options[:input_file])
dictionary = load_dictionary(options[:dictionary_file])
translated_data = translate_data(input_data, dictionary,  options[:col_numbers], options[:row_numbers], options[:keep_header])
translated_data.each do |record|
	puts record.join("\t")
end

