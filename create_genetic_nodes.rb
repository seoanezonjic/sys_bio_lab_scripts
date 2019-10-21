#! /usr/bin/env ruby

require 'optparse'

#METHODS

def load_file(file)
	storage = []
	File.open(file).each do |line|
		line.chomp!
		patients, cluster_id = line.split("\t")
		patients_cluster = patients.split(",")
		storage << [cluster_id, patients_cluster]
	end
	return storage 
end
#OPT-PARSER
options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: #{__FILE__} [options]"

  options[:cluster_file] = nil
  opts.on("-c", "--input_cluster_file PATH", "Input clustering file") do |file_path|
    options[:cluster_file] = file_path
  end

  options[:output_path] = "patient_file_overlapping.txt"
  opts.on("-o", '--output_path PATH', 'Output path for cluster-external patient file') do |output_path|
  	options[:output_path] = output_path
  end
end.parse!

#MAIN
clustering_info = load_file(options[:cluster_file])
first_layer = File.open(options[:output_path], "w")
clustering_info.each do |node_id, patients|
	patients.each do |patient|
		first_layer.puts "#{node_id}\t#{patient}" 
	end
end
first_layer.close