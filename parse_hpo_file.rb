#! /usr/bin/env ruby

#Code to parse files from HPO database.

###############################
#METHODS
###############################

def load_hpo_file(file)
	storage = []
	id = nil
	name = nil
	alt_id = []
	syn = []
	is_a = []
	File.open(file).each do |line|
		line.chomp!
		tag, info = line.split(': ')
		if tag == 'id' || tag == 'name' || tag == 'is_a' || tag == 'synonym' || tag == 'alt_id'
			if tag == 'id'
				storage << [id, alt_id.join('|'), name, syn.join('|')].concat(is_a) if !name.nil?  #if !temp[1].include?("obsolete") 
				id = info
				name = nil
				alt_id = []
				syn = []
				is_a = []
			end
			if tag == 'alt_id'
				alt_id << info
			elsif tag == 'is_a'
				is_a.concat(info.split(' ! '))
			elsif tag == 'synonym'
				syn << info.split('"')[1]
			else
				name = info
			end
		end
	end
	storage << [id, alt_id.join('|'), name, syn.join('|')].concat(is_a)
	return storage
end

###############################
#MAIN
###############################
storage = load_hpo_file(ARGV[0])
storage.each do |array|
	puts array.join("\t")
end

