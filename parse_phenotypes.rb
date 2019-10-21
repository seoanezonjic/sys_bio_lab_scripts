#! /usr/bin/env ruby
# Code to join files hpo2name.txt and decipher_patient2phenotype by patient and hpo code.
# Enrichment of patients phenotypes.

##########################
#RUBY GEMS
##########################
require 'optparse'

##########################
#METHODS
##########################
def load_hpo_file(hpo_file, hpo_black_list)
	storage = {}
	File.open(hpo_file).each do |line|
		line.chomp!
		fields = line.split("\t")
		hpo_code = fields.shift
		next if hpo_black_list.include?(hpo_code)
		alt_hpo_code = fields.shift
		phenotype = fields.shift
		synonyms = fields.shift 
		relations = []
		fields.each_slice(2) do |pair|
			#pair = HPO code, phenotype
			relations << pair
		end
		storage[phenotype] = [hpo_code, relations]
		if !synonyms.nil?
			synonyms.split('|').each do |syn|
				storage[syn] = [hpo_code, relations]
			end
		end
	end
	return storage
end

def load_hpo_black_list(excluded_hpo_file)
	excluded_hpos = []
	File.open(excluded_hpo_file).each do |line|
		line.chomp!
		excluded_hpos << line
	end
	return excluded_hpos
end

def load_patient_file(patient_file, hpo_ontology, parents)
	patients = {}
	hpo_stats = {}
	not_found = []
	File.open(patient_file).each do |line|
		line.chomp!
		patient, phenotype = line.split("\t")
		get_all_hpos(patient, phenotype, patients, hpo_ontology, hpo_stats, not_found, parents)
	end
	return patients, hpo_stats, not_found
end

def get_all_hpos(patient, phenotype, patients, hpo_ontology, hpo_stats, not_found, parents)
	query = hpo_ontology[phenotype]
	if !query.nil?
		hpo_code, relations = query
		query_stats = hpo_stats[hpo_code] # Do tracking of patients that have an hpo
		if query_stats.nil?
			hpo_stats[hpo_code] = [patient]
		elsif !query_stats.include?(patient)
			query_stats << patient
		end
		query_patient = patients[patient]
		if query_patient.nil?
		        patients[patient] = [hpo_code]
		else
		        query_patient << hpo_code
		end
		if !relations.nil? && parents # ADDING PARENTAL PHENOTYPES TO PATIENT
		    relations.each do |rel_code, rel_name|
		        get_all_hpos(patient, rel_name, patients, hpo_ontology, hpo_stats, not_found, parents)
	        end
	    end
	else
		not_found << phenotype if !not_found.include?(phenotype)
	end
end

##########################
#OPT-PARSE
##########################
options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: #{__FILE__} [options]"

  options[:hpo_file] = nil
  opts.on("-p", "--hpo_file PATH", "Input hpo codes file") do |hpo_path|
    options[:hpo_file] = hpo_path
  end

  options[:excluded_hpo] = nil
  opts.on("-e", "--excluded_hpo PATH", "List of HPO phenotypes to exclude (low informative)") do |excluded_hpo|
    options[:excluded_hpo] = excluded_hpo
  end

  options[:patient_file] = nil
  opts.on("-d", "--patient_file PATH", "Input patients with associated phenotype file") do |patient_path|
    options[:patient_file] = patient_path
  end

  options[:thresold] = 1
  opts.on("-t", "--info_thresold FLOAT", "Thresold to discard non informative hpo") do |thresold|
    options[:thresold] = thresold.to_f
  end 

  options[:parents] = true
  opts.on("-r", "--no_parents", "Switch for not including HPO parents in results") do
    options[:parents] = false
  end 

  options[:do_freq] = false
  opts.on("-f", "--do_freq", "Switch for calculate HPO frequency instead of IC") do
    options[:do_freq] = true
  end 

end.parse!


##########################
#MAIN
##########################
hpo_black_list = load_hpo_black_list(options[:excluded_hpo])
hpoNameDictionary = load_hpo_file(options[:hpo_file], hpo_black_list)
patients, hpo_stats, not_found = load_patient_file(options[:patient_file], hpoNameDictionary, options[:parents])
not_found = not_found - hpo_black_list
File.open('missing_hpo_names', 'w'){|f| f.puts not_found}
number_patients = patients.length
patients.each do |patient, code|
	stat= nil
	result=nil
  code.uniq.each do |c|
    stat = hpo_stats[c].length.to_f / number_patients #hpo frequency in patients
    result = -Math.log10(stat)
    if result >= options[:thresold]
    	if options[:do_freq]
    		puts "#{c}\t#{stat}"
    	else
    		puts "#{patient}\t#{c}\t#{result}"  
    	end
    end
  end
end
