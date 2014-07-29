#!/usr/bin/env ruby

######## PARAMS

# DATABASE = :Orient
DATABASE = :Postgres
POSTGRES_PORT = '5432'

ORIENT_PATH = '/Users/stevenli/releases/orientdb'
ORIENT_BIN_PATH = "#{ORIENT_PATH}/bin"
ORIENT_DATABASE_PATH = "local:#{ORIENT_PATH}/databases/tags"

if DATABASE == :Orient
  FILENAME = "ORIENT_BIN_PATH/#{DATABASE}_tag_inserts"
elsif DATABASE == :Postgres
  FILENAME = "#{DATABASE}_tag_inserts"
end

HASHC = {
  'Country' => 3,
  'Sport' => 9,
  'League' => 18,
  'Division' => 54,
  'Team' => 270,
  'Player' => 2700
}

HASHG = {
  1 => ['Division', (1..4)],
  2 => ['Team', (40..50)],
  3 => ['Team', (50..55)],
  4 => ['Team', (60..70)],
  5 => ['Player', (100..150)],
  6 => ['Player', (200..235)],
  7 => ['Player', (350..400)],
  8 => ['Player', (500..600)]
}

######## HELPERS

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
  end
end

def create_edge(name1, name2, options={})
  case DATABASE
  when :Orient
    "create edge from (select from Tag where name = \"#{name1}\") to (select from Tag where name = \"#{name2}\")"
  when :Postgres
    "INSERT INTO tag_relationships (parent_id, child_id) VALUES ((SELECT tags.id FROM tags where name = '#{name1}'), (SELECT tags.id FROM tags where name = '#{name2}'));"
  end
end

def tree_insert_queries
  File.open(FILENAME, 'a') do |file|
    types = HASHC.keys << nil
    types.each_with_index do |type, index|
      return unless type
      parent = types[index-1]
      HASHC[type].times do |indx|
        file.puts create_vertex('Tag', "#{type} #{indx + 1}", "#{type}")
        next unless parent
        denom = (HASHC[type]/HASHC[parent])
        parent_index = ((indx+1)/denom.to_f).ceil
        file.puts create_edge("#{parent} #{parent_index}", "#{type} #{indx+1}")
      end
    end
  end
end

def cycle_insert_queries
  File.open(FILENAME, 'a') do |file|
    HASHG.each do |group_index, array|
      file.puts create_vertex('Tag', "Group #{group_index}", 'Group', :many_to_many => true)
      type, range = array
      range.each do |type_index|
        file.puts create_edge("Group #{group_index}", "#{type} #{type_index}", :many_to_many => true)
      end
    end
  end
end

######## EXECUTION

File.open(FILENAME, 'w') do |file|
  case DATABASE
  when :Orient
    file.write("connect #{ORIENT_DATABASE_PATH} admin admin\n")
  when :Postgres
    file.write("\\connect tags_benchmarking\n")
  end
end

# Create Tree
tree_insert_queries

# Create Cycles
cycle_insert_queries

case DATABASE
when :Orient
  `cd #{ORIENT_BIN_PATH}`
  `./console.sh #{FILENAME}`
when :Postgres
  `psql -p #{POSTGRES_PORT} < #{FILENAME}`
end

`rm #{FILENAME}`