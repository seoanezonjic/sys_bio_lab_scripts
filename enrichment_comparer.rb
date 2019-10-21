#! /usr/bin/env ruby
require 'optparse'
###############################################
## METHODS
##############################################
def load_enrichment_file(path)
	enrichment_data = {}
	count = 0
	File.open(path).each do |line|
		if count > 0
			line.chomp!
			fields = line.split("\t")
			termA = fields.shift
			termB = fields.shift
			query = enrichment_data[termA]
			if query.nil?
				enrichment_data[termA] = [termB]
			else
				query << termB
			end
		end
		count += 1
	end
	return enrichment_data
end

##########################################################################################
## OPTPARSE
##########################################################################################

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: #{__FILE__} [options]"

  options[:single_enrichment] = nil
  opts.on("-s", "--single_enrichment PATH", "Input single enrichment file") do |file|
    options[:single_enrichment] = file
  end

  options[:pair_enrichment] = nil
  opts.on("-p", "--pair_enrichment PATH", "Input pair enrichment file") do |file|
    options[:pair_enrichment] = file
  end


end.parse!



##############################################
## MAIN
#############################################
single_enrichment_data = load_enrichment_file(options[:single_enrichment])
pair_enrichment_data = load_enrichment_file(options[:pair_enrichment])

pair_enrichment_data.each do |term_pair, pair_enriched_terms|
	termA, termB = term_pair.split('-')
	termA_enriched_terms = single_enrichment_data[termA]
	termB_enriched_terms = single_enrichment_data[termB]
	enriched_term_union = pair_enriched_terms
	enriched_term_union = enriched_term_union | termA_enriched_terms if !termA_enriched_terms.nil?
	enriched_term_union = enriched_term_union | termB_enriched_terms if !termB_enriched_terms.nil?
	enriched_term_union.each do |enriched_term|
		count = []
		if !termA_enriched_terms.nil? && termA_enriched_terms.include?(enriched_term)
			count << 1
		else
			count << 0
		end
		if !termB_enriched_terms.nil? && termB_enriched_terms.include?(enriched_term)
			count << 1
		else
			count << 0
		end
		if pair_enriched_terms.include?(enriched_term)
			count << 1
		else
			count << 0
		end
		puts "#{termA}\t#{termB}\t#{enriched_term}\t#{count.join("\t")}"
	end
end
