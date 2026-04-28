#!/usr/bin/env ruby

initial_job = ARGV[0].to_i
final_job =ARGV[1].to_i
while initial_job <= final_job 
	cmd = "scancel #{initial_job}"
	system(cmd)
	initial_job +=1
end
