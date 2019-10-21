#! /usr/bin/env ruby

require 'optparse'

##########################################################################################
## METHODS
##########################################################################################

def load_relations(file)
	relations = {}
	File.open(file).each do |line|
		line.chomp!
		term, relation = line.split("\t")
		query = relations[term]
		if query.nil?
			relations[term] = [relation]
		else
			query << relation
		end
	end
	return relations
end

##########################################################################################
## OPTPARSE
##########################################################################################

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: #{__FILE__} [options]"

  options[:pairs2merge] = nil
  opts.on("-p", "--pairs2merge PATH", "Input two tabulated columns file with the pairs to merge") do |input_file|
    options[:pairs2merge] = input_file
  end

  options[:relations2merge] = nil
  opts.on("-m", "--relations2merge PATH", "Input two tabulated columns file with the relations to merge") do |input_file|
    options[:relations2merge] = input_file
  end


end.parse!



##########################################################################################
## MAIN
##########################################################################################

relations = load_relations(options[:relations2merge])
File.open(options[:pairs2merge]).each do |line|
	line.chomp!
	termA, termB = line.split("\t")
	rels_A = relations[termA]
	rels_B = relations[termB]
	current_rels = []
	current_rels.concat(rels_A) if !rels_A.nil?
	current_rels.concat(rels_B) if !rels_B.nil?
	current_rels.uniq!
	current_rels.each do |curr_rel|
		puts "#{termA}-#{termB}\t#{curr_rel}"
	end
end
