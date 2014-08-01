def cycle_generator(num_of_cycles, name_of_vertices, num_of_vertices)
  output_hash = {}
  width = (num_of_vertices/num_of_cycles.to_f).floor
  (1..num_of_cycles).to_a.each_slice(width).to_a.each_with_index do |sub_array, index|
    output_hash[index] = [name_of_vertices, sub_array]
  end
  output_hash
end

class Counter
  @@current = 0
  def self.inc
    @@current = @@current + 1
  end
end

def create_vertex(klass, name, type, options={})
  case DATABASE
  when :Orient
    "create vertex #{klass} content {name: \"#{name}\", type: \"#{type}\"}"
  when :Postgres
    "INSERT INTO tags (id, name, type) VALUES ('#{Counter.inc}', '#{name}', '#{type}');"
  when :Neo4j
    "CREATE (type:#{type} { name: '#{name}' });"
  end
end

def create_edge(name1, name2, options={})
  case DATABASE
  when :Orient
    "create edge from (select from Tag where name = \"#{name1}\") to (select from Tag where name = \"#{name2}\")"
  when :Postgres
    "INSERT INTO tag_relationships (parent_id, child_id) VALUES ((SELECT tags.id FROM tags where name = '#{name1}'), (SELECT tags.id FROM tags where name = '#{name2}'));"
  when :Neo4j
    "MATCH (x), (y) WHERE x.name = '#{name1}' AND y.name = '#{name2}' CREATE (x)-[r:Parent]->(y);"
  end
end

def tree_insert_queries
  File.open(FILENAME, 'a') do |file|
    types = TREE.keys << nil
    types.each_with_index do |type, index|
      return unless type
      parent = types[index-1]
      TREE[type].times do |indx|
        file.puts create_vertex('Tag', "#{type} #{indx + 1}", "#{type}")
        next unless parent
        denom = (TREE[type]/TREE[parent])
        parent_index = ((indx+1)/denom.to_f).ceil
        file.puts create_edge("#{parent} #{parent_index}", "#{type} #{indx+1}")
      end
    end
  end
end

def cycle_insert_queries
  File.open(FILENAME, 'a') do |file|
    CYCLES.each do |group_index, array|
      file.puts create_vertex('Tag', "Group #{group_index}", 'Group', :many_to_many => true)
      type, range = array
      range.each do |type_index|
        file.puts create_edge("Group #{group_index}", "#{type} #{type_index}", :many_to_many => true)
      end
    end
  end
end
