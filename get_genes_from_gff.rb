#! /usr/bin/env ruby
require 'optparse'

##########################################################################################
## METHODS
#########################################################################################

def load_coordinates(file)
	coords = []
	File.open(file).each do |line|
		line.chomp!
		fields = line.split("\t")
		data = [fields[0], fields[1], fields[2].to_i, fields[3].to_i]
		coords << data
	end
	return coords
end

def load_gff3(file, feature, dbxref_name)
	features = {}
	chromosomes = {}
	chromosome_lengths = {}
	File.open(file).each do |line|
		line.chomp!
		next if line =~ />#/
		fields = line.split("\t")
		current_feature = fields[2]
		if current_feature == feature || current_feature == 'region'
			attributes = get_attributes(fields[8])
			if attributes['genome'] == 'chromosome'
				chromosomes[fields[0]] = attributes['chromosome']
				chromosome_lengths[attributes['chromosome']] = fields[4].to_i 
			elsif current_feature == feature
				gene_info = [fields[3].to_i, fields[4].to_i, attributes['Dbxref'][dbxref_name]]
				chr = chromosomes[fields[0]]
				query_chr = features[chr]
				if query_chr.nil?
					features[chr] = [gene_info]
				else
					query_chr << gene_info
				end
			end
		end
	end
	all = []
	features.each do |chr, coords|
		all.concat(coords.map{|i| i.last})
		coords.sort!{|c1, c2| c1[0] <=> c2[0] }
	end
	return features, chromosome_lengths
end

def get_attributes(attr_string)
	attrs = {}
	attr_string.split(';').each do |pair|
		key, val = pair.split("=", 2)
		if key == 'Dbxref'
			sub_attr = {}
			val.split(",").each do |sub_pair|
				sub_key, sub_val = sub_pair.split(":", 2)
				sub_attr[sub_key] = sub_val
			end
			val = sub_attr
		end
		attrs[key] = val
	end
	
	return attrs
end

def get_features(coords, gff)
	feature_table = {}
	coords.each do |tag, chr, start, stop|
		chr_coords = gff[chr]
		features = []
		chr_coords.each do |f_start, f_stop, f_id|
			if (start <= f_start && stop >= f_stop) ||
				(start >= f_start && stop <= f_stop) ||
				(start < f_start && stop > f_start) ||
				(start < f_stop && stop > f_stop) 
				features << f_id
			end
		end
		features.each do |feat_id|
			query_tag = feature_table[tag]
			if query_tag.nil?
				feature_table[tag] = { feat_id => true}
			else
				query_tag[feat_id] = true
			end
		end
	end
	return feature_table
end

##########################################################################################
## OPTPARSE
##########################################################################################

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: #{__FILE__} [options]"

  options[:coords_file] = nil
  opts.on("-c", "--coords_file PATH", "File with ranges to search in gff") do |file|
    options[:coords_file] = file
  end

  options[:gff_file] = nil
  opts.on("-g", "--gff_file PATH", "File in which search specified coordinates") do |file|
    options[:gff_file] = file
  end

  options[:chr_lengths] = false
  opts.on("-l", "--chr_lengths", "Generates only a table with the chromosome lengths") do 
    options[:chr_lengths] = true
  end

end.parse!

##########################################################################################
## MAIN
##########################################################################################



coords = load_coordinates(options[:coords_file])
gff,  chromosome_lengths = load_gff3(options[:gff_file], 'gene', 'GeneID')
if options[:chr_lengths]
	chromosome_lengths.each do |chrm, length|
		puts "#{chrm}\t#{length}"
	end
else
	feature_table = get_features(coords, gff)
	feature_table.each do |tag, feat_ids|
		feat_ids.each do |feat_id, val|
			puts "#{tag}\t#{feat_id}"
		end
	end
end
