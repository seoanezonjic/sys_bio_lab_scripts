#! /usr/bin/env ruby

require 'optparse'

############################################################################################
## METHODS
############################################################################################
def prof_match(profiles_A, profiles_B)
  best_matches = []
  percentages_A = {}
  prof_sizes_A = {}
  prof_sizes_B = {}
  profiles_A.each do |id_A, entities_A|
    matches = []
    best_count = 0
    profiles_B.each do |id_B, entities_B|
      count = (entities_A & entities_B).length
      if count >= best_count && count != 0
        matches << [id_B, count]
        best_count = count
        prof_sizes_B[id_B] = entities_B.length
      end  
    end
    percentages_A[id_A] = best_count.fdiv(profiles_A[id_A].length)
    if matches.length > 0
      best_id_matches = matches.select{|k| k.last == best_count}.map{|k| k.first}
      percentages_B = get_percentages(best_count, best_id_matches, profiles_B)
      max_percentages = percentages_B.max

      best_percentages = []
      percentages_B.each_with_index do |perc, i|
        if perc == max_percentages
          best_percentages << [best_id_matches[i], perc]
        end
      end
      best_matches << [id_A, best_percentages] 
    else
      best_matches << [id_A, []]
    end
    prof_sizes_A[id_A] = entities_A.length  
  end    
  best_matches.each do |id_A, data|
    data.each do |related_BID_and_perc|
    puts "#{id_A}" + "\t" + "#{related_BID_and_perc.first}" + "\t" + "#{percentages_A[id_A]}" + "\t" + "#{related_BID_and_perc.last}" + "\t" + "#{prof_sizes_A[id_A]}" + "\t" + "#{prof_sizes_B[related_BID_and_perc.first]}"
    end
  end
end

def get_percentages(best_count, best_ids, profiles_B)
  percentages = []
  best_ids.each_with_index do |best_id|
    percentages << best_count.fdiv(profiles_B[best_id].length)
  end
  return percentages
end

def parse_tsv_content(file, col_ref_ids, col_entities)
  parsed = {}
  File.open(file).each do |line|
    fields = line.chomp.split("\t")
    ref_id = fields[col_ref_ids]
    entity_id = fields[col_entities]    
    query = parsed[ref_id]
    if query.nil?
        parsed[ref_id] = [entity_id]
    else
        parsed[ref_id] << entity_id
    end
  end
  return parsed
end         

############################################################################################
## OPTPARSE
############################################################################################
options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: #{File.basename(__FILE__)} [options]"

  options[:profiles] = nil
  opts.on("-p", "--profiles PATH", "Path to tsv file containing ref_id to entity_id relationships") do |item|
    options[:profiles] = item
  end

  options[:target_profiles] = nil
  opts.on("-t", "--target_profiles PATH", "Path to target tsv ref_id to entity_id file. File containing the biggest avg size profiles must go here") do |item|
    options[:target_profiles] = item
  end

end.parse!


############################################################################################
## MAIN
############################################################################################
data = parse_tsv_content(options[:profiles], 0, 1)
target_data = parse_tsv_content(options[:target_profiles], 0, 1)    


prof_match(data, target_data)

