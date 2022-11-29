#! /usr/bin/env python
# coding: utf-8
import sys
import traceback
import argparse
#import optparse
from networkx import *
from collections import defaultdict

####################################################################################
## METHODS
###################################################################################





###################################################################################
## MAIN
################################################################################
if __name__=="__main__":
	parser = argparse.ArgumentParser(description="usage: %prog [options] arg1 arg2")
	parser.add_argument("-i", "--input", dest="input",
		help="File with pairs to cluster")
	parser.add_argument("-e", "--external", dest="external", default=None,
		help="File with external clustering")
	parser.add_argument("-o", "--output", dest="output", default="clusters.txt",
		help="Output file")
	parser.add_argument("-E", "--output_cluster_stats", dest="output_cluster_stats", default="stats_by_cluster.txt",
		help="Metrics by cluster output file")
	parser.add_argument('-g', '--cluster_stats', action='store_true', default=False,
		help="Activate metrics by cluster")
	parser.add_argument('-p', '--partial_clusters', action='store_true', default=False,
		help="Allow expand clusters with unconnected members")
	options = parser.parse_args()

	print(options)
		
	f = open(options.input, 'r')
	g = nx.Graph()
	for line in f:
		fields = line.strip("\n").split("\t")
		g.add_edge(fields[0], fields[1], weight= float(fields[2]))
	
	f = open(options.external, 'r')
	coms_to_node = defaultdict(list)
	for line in f:
		fields = line.strip("\n").split("\t")
		com_id = fields[0]
		node = fields[1]
		if g.has_node(node):
			coms_to_node[fields[0]].append(fields[1])
		else:
			print(node + ' node id from cluster ' + com_id + ' not exists in network' +'\n')

	com_stats = []
	expanded_clusters = []
	for com_id in coms_to_node:
		com = coms_to_node[com_id]
		if len(com) < 2:
			continue 
		path_lens = []
		path_nodes = []
		connected = True
		while len(com) > 1 and connected:
			source = com.pop(0)
			for target in com:
				sht_paths = nx.all_shortest_paths(g, source=source, target=target, weight='weight', method='dijkstra')
				nodes = []
				try:
					for stp in sht_paths:
						#print("\t".join(stp)+"\n")
						path_lens.append(len(stp))
						for n in stp:
							if n not in nodes:
								nodes.append(n)
					path_nodes.extend(nodes)
				except NetworkXNoPath as err:
					print("Net path error in cluster id " + com_id + ": {0}".format(err))
					path_lens = None
					if options.partial_clusters:
						continue
					else:
						connected = False
						break
		if options.cluster_stats:
			if path_lens is not None:
				average_path_len = sum(path_lens) / len(path_lens) -1 
			else:
				average_path_len = None

			com_stats.append([com_id, str(average_path_len)])

		if options.output is not None:
			expanded_clusters.append([com_id, list(set(path_nodes))])

	if options.cluster_stats:
		f = open(options.output_cluster_stats, "w")
		for com_stat in com_stats:
			f.write("\t".join(com_stat) +"\n")
		f.close()

	if options.output is not None:
		f = open(options.output, "w")
		for expanded_cluster in expanded_clusters:
			com_id = expanded_cluster[0]
			nodes = expanded_cluster[1]
			for node in nodes: 
				f.write(com_id + "\t" + node +"\n")
		f.close()
