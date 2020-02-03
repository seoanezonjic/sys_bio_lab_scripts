#! /usr/bin/env ruby



def load_target(file)
	samples = []
	count = 0
	replicates_position = nil
	treatment_position = nil
	File.open(file).each do |line|
		line.chomp!
		fields = line.split("\t")
		if count == 0
			replicates_position = fields.index('replicate')
			replicates_position = -1 if replicates_position.nil? # Replicates column was not found
			treatment_position = fields.index('treat')
		else
			if replicates_position == -1 # Replicates column was not found
				samples << [fields.first, nil, fields[treatment_position]]
			else
				samples << [fields.first, fields[replicates_position], fields[treatment_position]]
			end

		end
		count += 1
	end
	treatments = samples.map{|sample| sample[2]}.uniq
	final_target = {}
	treatments.each do |treat|
		final_target[treat] = samples.select{|sample| sample[2] == treat}.map{|sample| sample[0..1]}.sort{|s1, s2| s1[1] <=> s2[1] }
	end
	
	header = []
	final_target.each do |treat, samples|
		samples.each do |sample|
			header << sample[0] 
		end
	end
	return final_target, header

end

def load_mappings(target, root_folder, path_file, no_skip_header)
	all_seqs = []
	target.each do |treat, samples|
		samples.each do |sample|
			id, replicate = sample
			maps = {}
			file_path = File.join(root_folder, id, path_file)
			Dir.glob(file_path).each do |map_file|
				stats = load_map_file(map_file, no_skip_header)
				file_name = File.basename(map_file)
				maps[file_name] = stats
				all_seqs.concat(stats.keys)
				all_seqs.uniq!
			end
			sample << maps
		end
	end
	return all_seqs
end

def load_map_file(map_file, no_skip_header)
	stats = {}
	count = 0
	File.open(map_file).each do |line|
		line.chomp!
		fields = line.split("\t")
		if count > 0 || !no_skip_header.nil?
			stats[fields[0]] = fields[1]

		end
		count += 1
	end
	return stats
end

def write_tables(output_folder, target, all_seqs, header)
	files = {}
	target.each do |treat, samples|
		samples.each do |id, replicate, stats|
			stats.each do |source_file, st|
				table = files[source_file]
				if table.nil?
					table = []
					all_seqs.length.times do
						table << []
					end
					files[source_file] = table
				end
				all_seqs.each_with_index do |seq_name, ind|
					value = st[seq_name]
					if value.nil?
						table[ind] << "0"
					else
						table[ind] << value
					end
				end
			end
		end
	end
	files.each do |name, counts|
		handler = File.open(File.join(output_folder, name), 'w')
		handler.puts [nil].concat(header).join("\t")
		counts.each_with_index do |vals, ind|
			handler.puts "#{all_seqs[ind]}\t#{vals.join("\t")}"
		end
		handler.close
	end
end 
#####################################
## MAIN
#####################################

target, header = load_target(ARGV[0])
root_folder = ARGV[1]
path_file = ARGV[2]
output_folder = ARGV[3]
no_skip_header = ARGV[4]
all_seqs = load_mappings(target, root_folder, path_file, no_skip_header)
write_tables(output_folder, target, all_seqs, header)
