require 'pry'

class Graph
  attr_reader :nodes, :edges

  def initialize(args = {})
    @nodes = {}
    @edges = {}

    if args[:data]
      initialize_data(args[:data])
    end
  end

  def find_edge(start_node, end_node)
    edges.select {|edge| edge.start_node == start_node && edge.end_node == end_node}.first
  end

  def add_node(node)
    nodes[node.name] ||= node
  end

  def add_edge(edge)
    if edges.has_key?(edge.hash_key)
      raise "Existing edge already added before"
    else
      edges[edge.hash_key] = edge
      edge.start_node.add_outgoing_edge(edge)
      edge.end_node.add_incoming_edge(edge)
    end
  end

  def delete_edge(edge)
    if !edges.has_key?(edge.hash_key)
      raise "Unable to delete nonexisting edge"
    else
      edges.delete(edge.hash_key)
      edge.start_node.delete_outgoing_edge(edge)
      edge.end_node.delete_incoming_edge(edge)
    end
  end

  def to_s
    s = ""
    s << @nodes.values.map(&:to_s).join(", ")
    s << ("\n")
    s << @edges.values.map(&:to_s).join("\n")
  end

  private
    def initialize_data(data)
      data.each do |datum|
        # TODO: Buggy since this doesn't use old nodes!
        ower = Node.new(name: datum.ower)
        owed = Node.new(name: datum.owed)

        add_node(ower)
        add_node(owed)

        add_edge(Edge.new(ower, owed, datum.amount))
      end
    end
end

class Node
  attr_reader :name
  attr_reader :incoming_edges, :outgoing_edges

  def initialize(args = {})
    @name = args[:name]
    @incoming_edges = args[:incoming_edges] || []
    @outgoing_edges = args[:outgoing_edges] || []
  end

  def add_outgoing_edge(edge)
    outgoing_edges << edge
  end

  def add_incoming_edge(edge)
    incoming_edges << edge
  end

  def delete_outgoing_edge(edge)
    outgoing_edges.delete(edge)
  end

  def delete_incoming_edge(edge)
    incoming_edges.delete(edge)
  end

  def edges
    outgoing_edges + incoming_edges
  end

  def ==(object)
    self.class == object.class && self.name == object.name
  end

  def eql?(object)
    self == object
  end

  def to_s
    name
  end

  def inspect
    name
  end
end

class Edge
  attr_reader :start_node, :end_node, :weight

  def initialize(start_node, end_node, weight)
    @start_node = start_node
    @end_node = end_node
    @weight = weight.to_f
  end

  def hash_key
    [start_node, end_node]
  end

  def reverse!
    start_node.outgoing_edges.delete(self)
    start_node.incoming_edges << self

    end_node.incoming_edges.delete(self)
    end_node.outgoing_edges << self

    @start_node, @end_node = [end_node, start_node]
    @weight = -weight
  end

  def to_s
    "#{start_node} -> #{end_node} #{weight}"
  end

  def inspect
    to_s
  end
end

class Parser
  attr_reader :path

  def initialize(path)
    @path = path
  end

  def data
    @data ||= parse_data
  end

  private
    def parse_data
      read_data = []

      File.readlines(path).each do |line|
        next if line.strip.empty?
        ower, owed, amount = line.match(/\s*(\w+)\s*->\s*(\w+)\s*\$(\d+\.?\d*)/).captures

        read_data << TransactionData.new(ower: ower, owed: owed, amount: amount)
      end

      read_data
    end
end

class TransactionData
  attr_reader :ower, :owed, :amount

  def initialize(args = {})
    @ower = args[:ower]
    @owed = args[:owed]
    @amount = args[:amount]
  end

  def to_s
    "[#{ower}, #{owed}, #{amount}]"
  end
end

class Runner

  def run
    graph.nodes.each do |node_name, node|
      continue if node.edges.empty?

      puts graph

      puts "start"
      puts node
      puts "incoming"
      puts node.incoming_edges
      puts "outgoing"
      puts node.outgoing_edges
      puts "end"

      # 1. Make all the edges outgoing
      node.incoming_edges.each {|edge| edge.reverse! }


      # 2. For each edge, combine them into one by doing the following:
      #    If A -> B and A -> C, create an edge from B -> C so A -> B -> C
      final_edge = node.edges.first

      node.edges[1..-1].each do |edge|

        graph.delete_edge(edge)

        final_edge.weight += edge.weight

        # TODO: Just make a new edge instead of mutating the current
        starting_node = final_edge.ending_node
        ending_node = edge.ending_node

        existing_edge = graph.find_edge(new_starting_node, edge.ending_node)
        if existing_edge
          existing_edge.weight += edge.weight
        else
          graph.add_edge(Edge.new(starting_node, ending_node, edge.weight))
        end
      end

      # TODO: Remove
      return
    end

    # graph.nodes.each {|node| puts node.edges}
  end

  private
    def graph
      @graph ||= Graph.new(data: Parser.new("test.txt").data)
      # @graph ||= Graph.new(data: Parser.new("transaction_data.txt").data)
    end
end

Runner.new.run
