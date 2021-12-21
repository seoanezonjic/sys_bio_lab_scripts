#! /usr/bin/env ruby

require 'optparse'

#####################################################################
## METHODS
######################################################################

def load_records(file, cols, sep)
	recs = {}
	File.open(file).each do |line|
		fields = line.chomp.split(sep)
		recs[cols.map{|c| fields[c]}] = true
	end
	return recs.keys
end

def print_recs(recs, sep)
	recs.each do |rec|
		puts rec.join(sep)
	end
end

#####################################################################
## OPTPARSE
######################################################################

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: #{File.basename(__FILE__)} [options]"

  options[:a_file] = nil
  opts.on("-a", "--a_file PATH", "Path to input file") do |item|
    options[:a_file] = item
  end

  options[:b_file] = nil
  opts.on("-b", "--a_file PATH", "Path to input file") do |item|
    options[:b_file] = item
  end

  options[:a_cols] = [0]
  opts.on("-A", "--a_cols STRING", "Index of columns in base 0 to compare") do |item|
    options[:a_cols] = item.split(',').map{|n| n.to_i}
  end

  options[:b_cols] = [0]
  opts.on("-B", "--b_cols STRING", "Index of columns in base 0 to compare") do |item|
    options[:b_cols] = item.split(',').map{|n| n.to_i}
  end

  options[:count] = false
  opts.on("-c", "--count", "Only compute number of matches") do
    options[:count] = true
  end

  options[:keep] = 'c'
  opts.on("-k", "--keep STRING", "Keep records. c for common, 'a' for specific of file a, 'b' for specific of file b and 'ab' for specific of file a AND b") do |item|
    options[:keep] = item
  end

  options[:sep] = "\t"
  opts.on("-s", "--separator STRING", "column character separator") do |item|
    options[:sep] = item
  end

  opts.on_tail("-h", "--help", "Show this message") do
    puts opts
    exit
  end
end.parse!

a_records = load_records(options[:a_file], options[:a_cols], options[:sep])
b_records = load_records(options[:b_file], options[:b_cols], options[:sep])

common = a_records & b_records
a_only = a_records - common
b_only = b_records - common
if options[:count]
	puts "a: #{a_only.length}"
	puts "b: #{b_only.length}"
	puts "c: #{common.length}"
else
	if options[:keep] == 'c'
		print_recs(common, options[:sep])
	elsif options[:keep] == 'a'
		print_recs(a_only, options[:sep])
	elsif options[:keep] == 'b'
		print_recs(b_only, options[:sep])
	elsif options[:keep] == 'ab'
		print_recs(a_only + b_only, options[:sep])
	end
end
