Graph Theory
============

In short, the graph theory used here is based on finding the shortest path between two points that preserves the continuity of the interface. The input image is converted to a gradient image with the edge features protruding from the background. There are two main parameters in the function, node, and edge. Each pixel in the image is considered as a node in a graph and two nodes are connected by an edge. Therefore, the edge-detection process is transformed into a path-finding process. A set of connected edges form a pathway for one to travel across the graph. Weights can be assigned to individual edges to create path preferences. (The graph construction step is to assign cost values to each node in the graph). To travel across the graph from a start node (seed) to an end node, the preferred path is the route in which the total weight sum is at a minimum. This resulting path is the cut that segments one region from another.

There are many ways to calculate the cost of each node, as long as the feature to be segmented has characteristics unique to its surroundings, low weights can be assigned to the borders of that feature to distinguish it from the rest of the image.


The weights between two nodes are calculated based on intensity gradients as follows:
:math:`w_{ab}= 2- (g_{a}+g_{b})+w_{min}`


