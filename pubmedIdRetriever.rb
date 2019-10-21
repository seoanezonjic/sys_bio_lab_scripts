#! /usr/bin/env ruby

require 'net/http'
require 'json'

def load_query_file(file_path)
	queries = []
	File.open(file_path).each do |line|
		line.chomp!
		queries << line.split("\t")
	end
	return queries
end

def get_data(queries, max_entries=100000)
	results = []
	processed = []
	temp_file = 'processed.temp'
	if File.exists?(temp_file)
		proc_file = File.open(temp_file, 'a+') #Read & write
		processed = proc_file.readlines.map{|l| l.chomp}
	else
		proc_file = File.open(temp_file, 'w') # Only write
	end
	queries.each do |fields|
		query = fields.first 
		if !processed.include?(query)
			query_string = query.downcase.gsub(' ', '+')
			url_string = "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi?db=pubmed&term="+ query_string +"&field=Title%2FAbstract&retmax=#{max_entries}&retmode=json"
			uri = URI(url_string)
			response = Net::HTTP.get_response(uri)
			if response.code == '200'
				data = JSON.parse(response.body)
				count = data['esearchresult']['count']
				if count != '0'
					idlist = data['esearchresult']['idlist']
				else
					idlist = []
				end
				results << [fields, count, idlist]
				processed << query
				proc_file.puts query
			else
				STDERR.puts "#{query} was failed"
			end
		end
	end
	proc_file.close
	return results
end


queries = load_query_file(ARGV[0])

results = get_data(queries)

results.each do |fields, count, idlist|
	puts "#{fields.join("\t")}\t#{count}\t#{idlist.join(",")}"
end
