#! /usr/bin/env python
# coding: utf-8
import sys
import traceback
import argparse
#import optparse
from networkx import *
from cdlib import algorithms, viz, evaluation
from cdlib.utils import suppress_stdout, convert_graph_formats, nx_node_integer_mapping
try:
    import igraph as ig
except ModuleNotFoundError:
        ig = None
####################################################################################
## METHODS
###################################################################################

def get_stats(graph, communities):
	#Fitness functions: summarize the characteristics of a computed set of communities.
	# Transitivity: average clustering coefficient of its nodes w.r.t. their connection within the community itself.
	# Conductance: fraction of total edge volume that points outside the community.
	# Significance: how likely a partition of dense communities appear in a random graph
	#Size: number of nodes in the community.
	#Surprise: measures the quality of the community structure (assumes that edges between vertices emerge randomly according to a hyper-geometric distribution).
	# Triangle: fraction of community nodes that belong to a triad.
	# Maximum fraction of edges of a node of a community that point outside the community itself.
	# Average fraction of edges of a node of a community that point outside the community itself.
	metrics = [ 'size', 'avg_transitivity', 'conductance', 'triangle_participation_ratio', 'max_odf', 'avg_odf', 'avg_embeddedness', 'average_internal_degree', 'cut_ratio', 'fraction_over_median_degree', 'scaled_density' ]
	results = []
	for metric in metrics:
		# https://www.kite.com/python/answers/how-to-call-a-function-by-its-name-as-a-string-in-python
		class_method = getattr(evaluation, metric)
		res = class_method(graph, communities)
		results.append(res)
	return( metrics, results)
		
def get_stats_by_cluster(graph, communities):
	# HAS NOT SUMMARY: 'surprise', 'significance'
	#metrics = [ 'size', 'avg_transitivity', 'conductance',  'triangle_participation_ratio', 'max_odf', 'avg_odf', 'avg_embeddedness' ]
	metrics = [ 'size', 'avg_transitivity', 'conductance', 'triangle_participation_ratio', 'max_odf', 'avg_odf', 'avg_embeddedness', 'average_internal_degree', 'cut_ratio', 'fraction_over_median_degree', 'scaled_density']
	cluster_results = []
	for metric in metrics:
		class_method = getattr(evaluation, metric)
		res = class_method(graph, communities, summary=False)
		cluster_results.append(res)
	return(metrics, cluster_results)



###################################################################################
## MAIN
################################################################################
if __name__=="__main__":
	parser = argparse.ArgumentParser(description="usage: %prog [options] arg1 arg2")
	parser.add_argument("-i", "--input", dest="input",
		help="File with pairs to cluster")
	parser.add_argument("-e", "--external", dest="external",
		help="File with external clustering")
	parser.add_argument("-o", "--output", dest="output", default="clusters.txt",
		help="Output file")
	parser.add_argument("-m", "--method", dest="method",
		help="Clustering method")
	parser.add_argument("-a", "--additional_options", dest="additional_options", default='',
		help="Additional options for clustering methods. It must be defines as '\"opt_name1\" : value1, \"opt_name2\" : value2,...' ")
	parser.add_argument('--bipartite', action='store_true', default=False,
		help="Clustering method")
	parser.add_argument("-S", "--output_stats", dest="output_stats", default="clusters_stats.txt",
		help="Stats output file")
	parser.add_argument("-s", "--stats", action='store_true', default=False,
		help="Activate cluster stats metrics calculation")
	parser.add_argument("-E", "--output_cluster_stats", dest="output_cluster_stats", default="stats_by_cluster.txt",
		help="Metrics by cluster output file")
	parser.add_argument('-g', '--cluster_stats', action='store_true', default=False,
		help="Activate metrics by cluster")
	options = parser.parse_args()

	print(options)
	exec('clust_kwargs = {' + options.additional_options +'}') # This allows inject custom arguments for each clustering method
    	
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
		communities = algorithms.leiden(g, weights='weight', **clust_kwargs)
	elif(options.method == 'louvain'):
		communities = algorithms.louvain(g, weight='weight', **clust_kwargs)
	elif(options.method == 'cpm'):
		communities = algorithms.cpm(g, weights='weight', **clust_kwargs)
	elif(options.method == 'der'):
		communities = algorithms.der(g, **clust_kwargs)
	elif(options.method == 'edmot'):
		communities = algorithms.edmot(g, **clust_kwargs)
	elif(options.method == 'eigenvector'):
		communities = algorithms.eigenvector(g, **clust_kwargs)
	elif(options.method == 'gdmp2'):
		communities = algorithms.gdmp2(g, **clust_kwargs)
	elif(options.method == 'greedy_modularity'):
		communities = algorithms.greedy_modularity(g, weight='weight', **clust_kwargs)
	#elif(options.method == 'infomap'):
	#	communities = algorithms.infomap(g)
	elif(options.method == 'label_propagation'):
		communities = algorithms.label_propagation(g, **clust_kwargs)
	elif(options.method == 'markov_clustering'):
		communities = algorithms.markov_clustering(g, **clust_kwargs)
	elif(options.method == 'rber_pots'):
		communities = algorithms.rber_pots(g, weights='weight', **clust_kwargs)
	elif(options.method == 'rb_pots'):
		communities = algorithms.rb_pots(g, weights='weight', **clust_kwargs)
	elif(options.method == 'significance_communities'):
		communities = algorithms.significance_communities(g, **clust_kwargs)
	elif(options.method == 'spinglass'):
		communities = algorithms.spinglass(g, **clust_kwargs)
	elif(options.method == 'surprise_communities'):
		communities = algorithms.surprise_communities(g, **clust_kwargs)
	elif(options.method == 'walktrap'):
		communities = algorithms.walktrap(g, **clust_kwargs)
	#elif(options.method == 'sbm_dl'):
	#	communities = algorithms.sbm_dl(g)
	#elif(options.method == 'sbm_dl_nested'):
	#	communities = algorithms.sbm_dl_nested(g)
	elif(options.method == 'lais2'):
		communities = algorithms.lais2(g, **clust_kwargs)
	elif(options.method == 'big_clam'):
		communities = algorithms.big_clam(g, **clust_kwargs)
	elif(options.method == 'danmf'):
		communities = algorithms.danmf(g, **clust_kwargs)
	elif(options.method == 'ego_networks'):
		communities = algorithms.ego_networks(g, **clust_kwargs)
	elif(options.method == 'egonet_splitter'):
		communities = algorithms.egonet_splitter(g, **clust_kwargs)
	elif(options.method == 'nmnf'):
		communities = algorithms.nmnf(g, **clust_kwargs)
	elif(options.method == 'nnsed'):
		communities = algorithms.nnsed(g, **clust_kwargs)
	elif(options.method == 'slpa'):
		communities = algorithms.slpa(g, **clust_kwargs)
	elif(options.method == 'bimlpa'):
		communities = actlgorithms.bimlpa(g, **clust_kwargs)
	elif(options.method == 'wcommunity'):
		communities = algorithms.wCommunity(g, **clust_kwargs)
	elif(options.method == 'aslpaw'):
		import warnings
		with warnings.catch_warnings():
			warnings.filterwarnings("ignore")
			communities = algorithms.aslpaw(g)
	elif(options.method == 'external'):
		from collections import defaultdict
		from cdlib import NodeClustering
		coms_to_node = defaultdict(list)
		f = open(options.external, 'r')
		for line in f:
			fields = line.strip("\n").split("\t")
			coms_to_node[fields[0]].append(fields[1])
		coms = [list(c) for c in coms_to_node.values()]
		communities = NodeClustering(coms, g, "external", method_parameters={}, overlap=True)
	else:
		print('Not defined method')
		sys.exit(0)
	print(communities.method_parameters)
	print(communities.overlap)
	print(communities.node_coverage)

	if(options.method == 'wcommunity'): #This method gives node names as numeric id, so we change to original node id
		g = convert_graph_formats(g, ig.Graph)
	
	if(options.method != 'external'):	
		f = open(options.output, "w")
		count=0
		for community in communities.communities:
			for node in community:
				if(options.method == 'wcommunity'): #This method gives node names as numeric id, so we change to original node id
					f.write(str(count) + "\t" + g.vs[node]['name'] +"\n")
				else:
					f.write(str(count) + "\t" + node +"\n")
			count += 1
		f.close()

	if(options.stats):
		metrics, results = get_stats(g, communities)
		f = open(options.output_stats, "w")
		count = 0
		for res in results:
			metric_name = metrics[count]
			f.write("\t".join([metric_name, str(res.score), str(res.max), str(res.min), str(res.std)]) + "\n")
			count += 1
		f.close()

	if(options.cluster_stats):
		metrics, results_by_cluster = get_stats_by_cluster(g, communities)
		cdlib_coms = communities.communities
		f = open(options.output_cluster_stats, "w")
		metrics.insert(0, 'cl_id')
		f.write("\t".join(metrics) + "\n")
		for cluster_id in range(len(cdlib_coms)):
			if("coms_to_node" in locals()): # Clustering is external and contains custom labels
				members = cdlib_coms[cluster_id]
				clust_label = ''
				for key, value in coms_to_node.items():
					if(value == members):
						clust_label = key
						break
			else:
				clust_label = str(cluster_id)
			cl_metrics = []
			for metric in results_by_cluster:
				cl_metrics.append(str(metric[cluster_id]))
			f.write(clust_label + "\t" + "\t".join(cl_metrics) +"\n")
		f.close()
