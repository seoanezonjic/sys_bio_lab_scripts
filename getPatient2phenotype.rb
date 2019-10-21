#! /usr/bin/env ruby

#Code for parsing latest DECIPHER files with phenotypes separated by pipes
#Since September 16
#File decipher-cnvs-grch37-2016-08-20.txt -> decipher_data.txt
#Output: patient_id, phenotype

##############################
#LIBRARIES
##############################
require 'optparse'

##############################
#METHODS
##############################
def loadPatientFile(input_file)
	File.open(input_file).each do |line|
		line.chomp!
		next if line.include?("#")
		info = line.split("\t", 5)
		patient = info[0]
		if info[4].nil? #For skipping patients without phenotypes
			puts "#{patient}\t#{nil}"
		else
			phenotypes = info[4].split("|")
			phenotypes.each do |phenotype|
				puts "#{patient}\t#{phenotype}"
			end
		end
	end
end

##############################
#OPTPARSE
##############################

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: #{__FILE__} [options]"

  options[:input_file] = nil
  opts.on("-i", "--input_file PATH", "Input file for parsing phenotypes") do |value|
    options[:input_file] = value
  end

end.parse!

##############################
#MAIN
##############################

loadPatientFile(options[:input_file])
