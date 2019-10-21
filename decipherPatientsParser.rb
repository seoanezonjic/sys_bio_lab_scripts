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
def loadDecipherFile(input_decipher)
	File.open(input_decipher).each do |line|
		line.chomp!
		next if line.include?("#")
		info = line.split("\t", 9)
		patient = info[0]
		if info[8].nil? #For skipping patients without phenotypes
			puts "#{patient}\t#{nil}"
		else
			phenotypes = info[8].split("|")
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

  options[:input_decipher] = nil
  opts.on("-i", "--input_decipher PATH", "Input DECIPHER file for parsing phenotypes") do |input_decipher|
    options[:input_decipher] = input_decipher
  end

end.parse!

##############################
#MAIN
##############################

loadDecipherFile(options[:input_decipher])
