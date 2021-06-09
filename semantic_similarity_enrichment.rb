#! /usr/bin/env ruby

require 'optparse'
require 'semtools'

#################################################################
## METHODS
#################################################################
def load_enrichment(input)
	clusters = {}
	header = true
	File.open(input).each do |line|
		if header
			header = false
			next
		end
		line.chomp!
		fields = line.split("\t")
		cl_id = fields.shift
		term_code = fields.shift.to_sym
		query = clusters[cl_id]
		if query.nil?
			clusters[cl_id] = [term_code]
		else
			query << term_code
		end
	end
	return clusters
end

def format_profiles_similarity_data(profiles_similarity)
  matrix = []
  element_names = profiles_similarity.keys
  matrix << element_names
  profiles_similarity.each do |elementA, relations|
    row = [elementA]
    element_names.each do |elementB|
      if elementA == elementB
        row << 'NA'
      else
        query = relations[elementB]
        if !query.nil?
          row << query
        else
          row << profiles_similarity[elementB][elementA]
        end
      end
    end
    matrix << row
  end
  matrix[0].unshift('pat')
  return matrix
end

def write_similarity_matrix(similarity_matrix, similarity_matrix_file)  
  File.open(similarity_matrix_file, 'w') do |f|
    similarity_matrix.each do |row|
      f.puts row.join("\t")
    end
  end
end

def get_dsi_dist(enrichment, ont)
	dsi_dist = []
	enrichment.each do |clust_id, terms|
		ont.profiles = {}
		ont.load_profiles({clust_id => terms})
		dsi_dist << [clust_id, ont.get_dataset_specifity_index('uniq')]
	end
	ont.profiles = {}
	return dsi_dist
end

#################################################################
## OPTPARSE
#################################################################
options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: #{__FILE__} [options]"

  options[:input] = nil
  opts.on("-i", "--input PATH", "Input file") do |data|
    options[:input] = data
  end

  options[:output] = 'out_matrix'
  opts.on("-o", "--output PATH", "Output file") do |data|
    options[:output] = data
  end

  options[:obo] = nil
  opts.on("-b", "--obo PATH", "obo input file") do |data|
    options[:obo] = data
  end

  opts.on_tail("-h", "--help", "Show this message") do
    puts opts
    exit
  end

end.parse!

#################################################################
## MAIN
#################################################################

enrichment = load_enrichment(options[:input])
ont = Ontology.new(file: options[:obo], load_file: true)
dsi_dist = get_dsi_dist(enrichment, ont)
ont.load_profiles(enrichment)
profiles_similarity = ont.compare_profiles(sim_type: :lin)
matrix_sim = format_profiles_similarity_data(profiles_similarity)
write_similarity_matrix(matrix_sim, options[:output])
File.open(options[:output]+'_dsi_dist', 'w') do |f|
	dsi_dist.each do |rec|
		f.puts rec.join("\t")
	end
end
