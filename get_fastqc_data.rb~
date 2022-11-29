#! /usr/bin/env ruby

require 'zip/zip'
require 'optparse'

#################################################################################################
## METHODS
################################################################################################
def parse_fastqc_data(fastqc_string)
    modules = {}
    last_module = nil
    mod = []
    fastqc_string.each_line do |line|
        line.chomp!
        next if line.include?('NaN')
        fields = line.split("\t")
        if fields.first == ">>END_MODULE"
            modules[last_module] = mod
            last_module = nil
            mod = []
        elsif fields.first == "##FastQC"
            next
        elsif fields.first =~ /^>>/
            last_module = fields.first.gsub('>>', '')
        else
            mod << fields
        end
    end
    processed_modules = {}
    processed_modules['general_stats'] = parse_general_stats(modules['Basic Statistics'])
    processed_modules['quality_per_base'] = parse_quality_per_base(modules['Per base sequence quality'])
    processed_modules['quality_per_sequence'] = parse_quality_per_sequence(modules['Per sequence quality scores'])
    processed_modules['indeterminations_per_base'] = parse_two_column_data(modules['Per base N content'])
    processed_modules['sequence_length_distribution'] = parse_two_column_data(modules['Sequence Length Distribution'])
    #puts processed_modules.inspect
    return processed_modules
end

def parse_general_stats(general_stats)
    stats = {}
    general_stats.shift # Remove header
    general_stats.each do |attrib, value|
        if attrib == "Total Sequences"
            stats[attrib] = value.to_i
        elsif attrib == '%GC'
            stats[attrib] = value.to_f
        elsif attrib == "Sequence length"
		if value.include?('-')
	            min, max = value.split('-')
        	    stats['Read_max_length'] = max.to_i
	            stats['Read_min_length'] = min.to_i
		else
        	    stats['Read_max_length'] = value.to_i
	            stats['Read_min_length'] = value.to_i
		end
        else
            stats[attrib] = value
        end
    end
    return stats
end

def parse_quality_per_base(quality_data)
    quality_data.shift
    quality_data.each do |data|
        base = data.shift
        data.map!{|d| d.to_f}.unshift(base)
    end
    return quality_data
end

def parse_quality_per_sequence(quality_data)
    quality_data.shift
    quality_data.each do |data|
        data.map!{|d| d.to_i }
    end
    return quality_data
end

def parse_two_column_data(data)
    data.shift
    new_data = []
    data.each do |base, count|
        new_data << [base, count.to_f]
    end
    return new_data
end

def get_mean(data, col)
    total = 0
    count = 0
    data.each do |d|
        total += d[col]
        count += 1
    end
    return total/count.to_f
end

def get_min(data, col)
    nums = []
    data.each do |d|
        nums << d[col]
    end
    return nums.min
end

def get_weighted_mean(data, col_val, col_weigth)
    total_weigth = 0
    sum_product = 0
    data.each do |d|
        total_weigth += d[col_weigth]
        sum_product += d[col_weigth] * d[col_val]
    end
    return sum_product.to_f/total_weigth
end

def get_weighted_mean_with_intervals(data, col_val, col_weigth)
    total_weigth = 0
    sum_product = 0
    data.each do |d|
        total_weigth += d[col_weigth]
        sum = 0
        d[col_val].split('-').map{|i| i.to_i}.each do |i|
            sum += i
        end
        sum_product += d[col_weigth] * sum.to_f
    end
    return sum_product.to_f/total_weigth
end

def parse_distributions(two_column_table)
    distribution_arr = []
    two_column_table.each do |row|
        distribution_arr << row.join(",")
    end
    distribution_string = distribution_arr.join(":")
    return distribution_string
end
#################################################################################################
## INPUT PARSING
#################################################################################################
options = {}

optparse = OptionParser.new do |opts|
        options[:input] = nil
        opts.on( '-i PATH', '--input_file PATH', 'File to process' ) do |string|
            options[:input] = string
        end

        options[:header] = false
        opts.on( '-H', '--header', 'Show header' ) do 
            options[:header] = true
        end

        options[:transpose] = false
        opts.on( '-T', '--transpose', 'Show stat matrix transposed' ) do 
            options[:transpose] = true
        end

       # Set a banner, displayed at the top of the help screen.
        opts.banner = "Usage: #{__FILE__} options \n\n"

        # This displays the help screen
        opts.on( '-h', '--help', 'Display this screen' ) do
                puts opts
                exit
        end

end # End opts

# parse options and remove from ARGV
optparse.parse!


###########################################################################################################
## MAIN
##########################################################################################################

all_stats = []
header = %w{total_sequences read_max_length read_min_length %gc mean_qual_per_base min_qual_per_base_in_lower_quartile min_qual_per_base_in_10th_decile weigthed_qual_per_sequence mean_indeterminations_per_base weigthed_read_length sequence_length_distribution}
Dir.glob(options[:input]).each do |file|
    modules = parse_fastqc_data(Zip::ZipFile.new(file).read(File.join(File.basename(file, '.zip'), "fastqc_data.txt")))
    stats = []
    stats << modules['general_stats']['Total Sequences']
    stats << modules['general_stats']['Read_max_length']
    stats << modules['general_stats']['Read_min_length']
    stats << modules['general_stats']['%GC']
    stats << get_mean(modules['quality_per_base'], 2)
    stats << get_min(modules['quality_per_base'], 3)
    stats << get_min(modules['quality_per_base'], 5)
    stats << get_weighted_mean(modules['quality_per_sequence'], 0,1)
    stats << get_mean(modules['indeterminations_per_base'], 1)
    stats << get_weighted_mean_with_intervals(modules['sequence_length_distribution'], 0,1)
    stats << parse_distributions(modules['sequence_length_distribution'])
    all_stats << stats
end

n_samples = all_stats.length
n_parameters = header.length
means = []
n_parameters.times do |parameter_index|
    if header[parameter_index] == 'sequence_length_distribution'
        all_distributions = []
        n_samples.times do |sample_index|
            all_distributions << all_stats[sample_index][parameter_index]
        end
        means << all_distributions.join(";")
    else
        sum = 0
        n_samples.times do |sample_index|
            sum += all_stats[sample_index][parameter_index]
        end
        means << sum.to_f/n_samples
    end
end
if !options[:transpose]
	puts header.join("\t") if options[:header]
	puts means.join("\t")
else
	means.each_with_index do |mean, i|
		record = []
		record << header[i] if options[:header]
		record << mean
		puts record.join("\t")
	end
end
