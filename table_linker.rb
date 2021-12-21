#!/usr/bin/env ruby
# Pedro Seoane Zonjic 13-12-2012
# Toma la informacion extraida de un archivo tabulado (donde la primera columna es el idetificador) en base a una lista de identificadores proporcionada
# la informacion se guarda en el archivo de salida

if ARGV.size < 3
	puts "Usage: table_linker.rb file_table file_table output_file_name"
	Process.exit
end

drop_line = false
if !ARGV[3].nil?
	drop_line = true
end
hash_info={}

#Cargar tabla de informacion en hash en forma {identificador => campos de informacion}
File.open(ARGV[0],'r').each do |line|
	fields=line.chomp.split("\t",2)
	hash_info[fields.first]=fields.last
end

save_info=File.open(ARGV[2],'w') #Crea archivo para guardar la informacion
File.open(ARGV[1],'r').each do |line|
	line.chomp!
	fields = line.split("\t")
	id = fields.first
	info_id=hash_info[id]
	if !info_id.nil?
		save_info.puts line+"\t"+info_id
	else
		save_info.puts line if !drop_line
	end
end
save_info.close
