#! /usr/bin/env ruby

require "benchmark"
require 'optparse'

##########################
#METHODS
##########################
# Input file structure: 
# PatientID	MutStart	MutStop	Chr
# 267369  53186624        138826345       X

def load_file(file_name)
	patients_info = {}
	File.open(file_name).each do |line|
		line.chomp!
		fields = line.split("\t")
		chrom_number = fields.delete_at(1)
		fields = fields[0..2]
		fields.map!{|a| a.to_i}
		query = patients_info[chrom_number]
		if query.nil?
			patients_info[chrom_number] = [fields]
		else
			query << fields
		end
	end
	return patients_info
end

def get_reference(genomic_ranges)
	#genomic_ranges = [patientID, mut_start, mut_stop]
	reference = []
	reference.concat(genomic_ranges.map{|gr| gr[1]})# get start
	reference.concat(genomic_ranges.map{|gr| gr[2]})# get stop
	reference.uniq!
	reference.sort!
	#Define overlap range
	final_reference = []
	reference.each_with_index do |coord,i|
		next_coord = reference[i + 1]
		final_reference << [coord, next_coord] if !next_coord.nil? 
	end
	return final_reference
end

def overlap_patients(genomic_ranges, reference)
	overlaps = []
	reference.each do |start, stop|
		patients = []
		genomic_ranges.each do |pt_id, pt_start, pt_stop|
			if (start <= pt_start && stop >= pt_stop) ||
				(start > pt_start && stop < pt_stop) ||
				(stop > pt_start && stop <= pt_stop) ||
				(start >= pt_start && start < pt_stop)
				patients << pt_id
			end
		end
		#code changed from patients to patients.uniq
		#in come cases, you can find the same patient with repeated coordinates
		#avoid repeated patients for including them in the cluster
		overlaps << patients.uniq
	end
	return overlaps
end

##########################
#OPT-PARSER
##########################

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: #{__FILE__} [options]"

  options[:file] = nil
  opts.on("-f", "--input_file PATH", "Input patient file") do |file_path|
    options[:file] = file_path
  end

  options[:mutation_type] = nil
  opts.on("-t", "--mutation_type STRING", "Type of patient mutation, either it is a deletion (d) or duplication (D)") do |type|
    options[:mutation_type] = type
  end

  options[:output_path] = "patient_file_overlapping.txt"
  opts.on("-o", '--output_path PATH', 'Output path for overlapping patient file') do |output_path|
  	options[:output_path] = output_path
  end
end.parse!


##########################
#MAIN
##########################

results_file = File.open(options[:output_path], 'w')
patients_info = load_file(options[:file])
clusters = []
patients_info.each do |chrm, genomic_ranges|
	reference = get_reference(genomic_ranges) # Get putative overlap regions
	overlapping_patients = overlap_patients(genomic_ranges, reference) # See what patient has match with a overlap region
	clust_number = 0
	reference.each_with_index do |ref, i|
		current_patients = overlapping_patients[i]
		if current_patients.length > 1
			ref << chrm
			ref << current_patients.join(",")
			#generate cluster number
			# pair = [chrm, current_patients]
			# clust_number = clusters.index(pair)
			# if clusters.empty?
			# 	clust_number = 0
			# 	clusters << pair
			# elsif clust_number.nil?
			# 	clust_number = clusters.length
			# 	clusters << pair 
			# end
			#----------------------------
			node_identifier = "#{chrm}.#{clust_number + 1}.#{options[:mutation_type]}.#{current_patients.length}"
			ref << node_identifier
			results_file.puts ref.join("\t")
			clust_number += 1
		end
	end
end
results_file.close
