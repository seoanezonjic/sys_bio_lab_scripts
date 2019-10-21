#! /usr/bin/env ruby

require 'optparse'
#################################################################################################
## METHODS
#################################################################################################
def load_rdm_names(file)
	return File.open(file).readlines.map{|line| line.chomp!}
end


#################################################################################################
## INPUT PARSING
#################################################################################################
options = {}
# -r dec -t 0.001 -m rdm_info -n 50 -i ~jabato/projects/rdm_annot_and_enrich/proyecto_fernando/results/kegg_enrichments
optparse = OptionParser.new do |opts|
        options[:input_file] = nil
        opts.on( '-i', '--input_file FILE', 'Input enrichment file' ) do |opt|
            options[:input_file] = opt
        end

        options[:reference_model] = nil
        opts.on( '-r', '--reference_model STRING', 'Reference model to use in significant term extraction' ) do |opt|
                options[:reference_model] = opt
        end

        options[:rdm_model_info] = nil
        opts.on( '-m', '--rdm_model_info PATH', 'Path to model table' ) do |opt|
                options[:rdm_model_info] = opt
        end

        options[:model_number] = 1
        opts.on( '-n', '--model_number INTEGER', 'Number of replicates for each model' ) do |opt|
                options[:model_number] = opt.to_i
        end

        options[:p_value_threshold] = 0.001
        opts.on( '-t', '--p_value_thresold FLOAT', 'Threshold for input enrichment entries' ) do |opt|
                options[:p_value_threshold] = opt.to_f
        end
	
        options[:col2process] = nil
        opts.on( '-c', '--col2process STRING', 'Column names comma separated, by order: model name, term and enriched term. Eg. "model_name,term,enriched_term"' ) do |opt|
                options[:col2process] = opt.split(',')
        end


        # Set a banner, displayed at the top of the help screen.
        opts.banner = "Usage: #{File.basename(__FILE__)} [options] \n\n"

        # This displays the help screen
        opts.on( '-h', '--help', 'Display this screen' ) do
                puts opts
                exit
        end

end # End opts

# parse options and remove from ARGV
optparse.parse!

##################################################################################################
## MAIN
##################################################################################################

rdm_names = load_rdm_names(options[:rdm_model_info])
model_info = {}
rdm_names.each{|name| model_info[name] = {}}
model_info[options[:reference_model]] = {}

count = 0
model_name_index = nil
term_index = nil
enriched_term_index = nil
File.open(options[:input_file]).each do |line|
	line.chomp!
	fields = line.split("\t")
	if count > 0
		model_name = fields[model_name_index].gsub(/\d+$/, '')
		model = model_info[model_name]
		next if model.nil?
		term = fields[term_index]
		enrichment = fields[enriched_term_index]
		term_query = model[term]
		if !term_query.nil?
			term_query[enrichment] += 1
		else
			stat_table = Hash.new(0)
			stat_table[enrichment] = 1
			model[term] = stat_table
		end
	else
		model_name_index, term_index, enriched_term_index = options[:col2process].map{|col_name| fields.index(col_name)}
	end
	count += 1
end
ref_terms = model_info.delete(options[:reference_model])
model_info.each do |model, term_data|
	ref_terms.each do |ref_term, ref_term_data|
		term = term_data[ref_term]
		if !term.nil?
			ref_term_data.each do |ref_enrichment, ref_value|
				value = term[ref_enrichment]
				term_model_pvalue = value.fdiv(options[:model_number])
				if term_model_pvalue <= options[:p_value_threshold]
					puts "#{model}\t#{ref_term}\t#{ref_enrichment}\t#{term_model_pvalue}"
				end
			end
		end
	end
end
