#! /usr/bin/env ruby

require 'optparse'

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: #{__FILE__} [options]"

  options[:input] = nil
  opts.on("-i", "--input_file PATH", "Path to input file") do |item|
    options[:input] = item
  end

  options[:col_index] = nil
  opts.on("-x", "--column_index INTEGER", "Column index (0 based) to use as reference") do |item|
    options[:col_index] = item.to_i
  end

  options[:sep] = ","
  opts.on("-s", "--sep_char STRING", "Field character delimiter") do |item|
    options[:sep] = item.to_i
  end

  opts.on_tail("-h", "--help", "Show this message") do
    puts opts
    exit
  end
end.parse!


agg_data = {}
if options[:input] == '-'
	input = STDIN
else
	input = File.open(options[:input])
end
input.each do |line|
	fields = line.chomp.split("\t")
	target_field = fields[options[:col_index]]
	target_field.split(options[:sep]).each do |val|
		record = fields[0..(options[:col_index]-1)] + [val] + fields[(options[:col_index] + 1)..fields.length]
		#record = fields[0..(options[:col_index] + 1)] + [val] + fields[(options[:col_index] + 1)..fields.length]
		STDOUT.puts record.join("\t")
	end
end

