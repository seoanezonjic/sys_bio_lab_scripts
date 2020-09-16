#! /usr/bin/env ruby

require 'optparse'

def load_file(path, expresion, header_exists)
	header = []
	data = []
	count = 0
	File.open(path).each do |line|
		fields = line.chomp.split("\t")
		if count == 0
			if header_exists
				header = fields
				count +=1 
				next
			else
				header = Array.new(fields.length, '-')
			end
		end
		coordinates = eval(expresion)
		coordinates[1] = coordinates[1].to_i
		coordinates[2] = coordinates[2].to_i
		data << coordinates.concat(fields)
		count += 1
	end
	return header, data
end

def coor_overlap?(ref_start, ref_stop, start, stop)
  overlap = false
  if (stop > ref_start && stop <= ref_stop) ||
    (start >= ref_start && start < ref_stop) ||
    (start <= ref_start && stop >= ref_stop) ||
    (start > ref_start && stop < ref_stop)
    overlap = true
  end
  return overlap
end

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: #{File.basename(__FILE__)} [options]"

  options[:file1path] = nil
  opts.on("-1", "--file1_path PATH", "Path to file 1, its columns will be the first in the table") do |item|
    options[:file1path] = item
  end

  options[:file2path] = nil
  opts.on("-2", "--file2_path PATH", "Path to file 2, its columns will be the last in the table") do |item|
    options[:file2path] = item
  end

  options[:fileExp1] = nil
  opts.on("-a", "--fe1 STRING", "Ruby expresion to extract sequence coordinates for file 1") do |item|
    options[:fileExp1] = item
  end

  options[:fileExp2] = nil
  opts.on("-b", "--fe2 STRING", "Ruby expresion to extract sequence coordinates for file 2") do |item|
    options[:fileExp2] = item
  end

  options[:header1] = true
  opts.on("-A", "--file1_no_header", "File 1 has no header") do
    options[:header1] = false
  end

  options[:header2] = true
  opts.on("-B", "--file2_no_header", "File 2 has no header") do
    options[:header2] = false
  end
end.parse!


header1, data1 = load_file(options[:file1path], options[:fileExp1], options[:header1])
header2, data2 = load_file(options[:file2path], options[:fileExp2], options[:header2])
puts (header1.concat(header2)).join("\t")
cols_file2 = header2.length
data1.each do |record1|
	chr1, start1, stop1 = record1.shift(3)
	match = Array.new(cols_file2)
	data2.each do |record2|
		chr2, start2, stop2 = record2
		if chr1 == chr2 && coor_overlap?(start1, stop1, start2, stop2)
			match = record2[3..cols_file2+2]  # the +2 it¡s for the coordinates fields added before (-1 by = based enumeraton y +3 for the three fields)
			break
		end
	end
	puts record1.concat(match).join("\t")
end
