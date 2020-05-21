#! /usr/bin/env python
# coding: utf-8
import sys
import argparse
#import optparse
from networkx import *
from cdlib import algorithms

if __name__=="__main__":
	parser = argparse.ArgumentParser(description="usage: %prog [options] arg1 arg2")
	parser.add_argument("-i", "--input", dest="input",
		help="File with pairs to cluster")
	parser.add_argument("-o", "--output", dest="output", default="clusters.txt",
		help="Output file")
	parser.add_argument("-m", "--method", dest="method",
		help="Clustering method")
	parser.add_argument('--bipartite', action='store_true', default=False)

	options = parser.parse_args()
	print(options)
    	
	f = open(options.input, 'r')
	g = nx.Graph()
	for line in f:
		fields = line.strip("\n").split("\t")
		if(options.bipartite):
			g.add_node(fields[0], bipartite=0)
			g.add_node(fields[1], bipartite=1)
		g.add_edge(fields[0], fields[1], weight= float(fields[2]))
	
	print(g.number_of_nodes())
	print(g.number_of_edges())
	if(options.method == 'leiden'):
		communities = algorithms.leiden(g, weights='weight')
	elif(options.method == 'louvain'):
		communities = algorithms.louvain(g, weight='weight')
	elif(options.method == 'cpm'):
		communities = algorithms.cpm(g, weights='weight')
	elif(options.method == 'der'):
		communities = algorithms.der(g)
	elif(options.method == 'edmot'):
		communities = algorithms.edmot(g)
	elif(options.method == 'eigenvector'):
		communities = algorithms.eigenvector(g)
	elif(options.method == 'gdmp2'):
		communities = algorithms.gdmp2(g)
	elif(options.method == 'greedy_modularity'):
		communities = algorithms.greedy_modularity(g, weight='weight')
	#elif(options.method == 'infomap'):
	#	communities = algorithms.infomap(g)
	elif(options.method == 'label_propagation'):
		communities = algorithms.label_propagation(g)
	elif(options.method == 'markov_clustering'):
		communities = algorithms.markov_clustering(g)
	elif(options.method == 'rber_pots'):
		communities = algorithms.rber_pots(g, weights='weight')
	elif(options.method == 'rb_pots'):
		communities = algorithms.rb_pots(g, weights='weight')
	elif(options.method == 'significance_communities'):
		communities = algorithms.significance_communities(g)
	elif(options.method == 'spinglass'):
		communities = algorithms.spinglass(g)
	elif(options.method == 'surprise_communities'):
		communities = algorithms.surprise_communities(g)
	elif(options.method == 'walktrap'):
		communities = algorithms.walktrap(g)
	#elif(options.method == 'sbm_dl'):
	#	communities = algorithms.sbm_dl(g)
	#elif(options.method == 'sbm_dl_nested'):
	#	communities = algorithms.sbm_dl_nested(g)
	elif(options.method == 'lais2'):
		communities = algorithms.lais2(g)
	elif(options.method == 'big_clam'):
		communities = algorithms.big_clam(g)
	elif(options.method == 'danmf'):
		communities = algorithms.danmf(g)
	elif(options.method == 'ego_networks'):
		communities = algorithms.ego_networks(g)
	elif(options.method == 'egonet_splitter'):
		communities = algorithms.egonet_splitter(g)
	elif(options.method == 'nmnf'):
		communities = algorithms.nmnf(g)
	elif(options.method == 'nnsed'):
		communities = algorithms.nnsed(g)
	elif(options.method == 'slpa'):
		communities = algorithms.slpa(g)
	elif(options.method == 'bimlpa'):
		communities = algorithms.bimlpa(g)
	else:
		print('Not defined method')
		sys.exit(0)
	print(communities.method_parameters)
	print(communities.overlap)
	print(communities.node_coverage)
	f = open(options.output, "w")
	count=0
	for community in communities.communities:
		for node in community:
			f.write(str(count) + "\t" + node +"\n")
		count += 1
	f.close()
