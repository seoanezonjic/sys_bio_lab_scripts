#! /usr/bin/env ruby

#Code to parse files from HPO database.

###############################
#METHODS
###############################

def load_hpo_file(file, fields)
	storage = []
	id = nil
	File.open(file).each do |line|
		line.chomp!
		tag, info = line.split(': ')
		if tag == 'id'
			id = info
			next
		end
		data = nil
		field = nil
		if fields.include?('name') && tag == 'name'
			data = info
			field = 'name'
		elsif fields.include?('alt_id') && tag == 'alt_id'
			data = info
			field = 'alt_id'
		elsif fields.include?('is_a') && tag == 'is_a'
			data = info.split(' ! ').first
			field = 'is_a'
		elsif fields.include?('synonym') && tag == 'synonym'
			data = info.split('"')[1]
			field = 'synonym'
		end
		storage << [data, id, field] if !data.nil?  
	end
	return storage
end

###############################
#MAIN
###############################
storage = load_hpo_file(ARGV[0], ARGV[1].split(','))
storage.each do |record|
	puts record.join("\t")
end

