#!/usr/bin/env ruby

require 'pry'

##### PARAMS

# Select a database
# DATABASE = :Orient
# DATABASE = :Postgres
DATABASE = :Neo4j

# POSTGRES
POSTGRES_PORT = '5432'

# ORIENT
ORIENT_PATH = '/Users/stevenli/releases/orientdb'
ORIENT_BIN_PATH = "#{ORIENT_PATH}/bin"
ORIENT_DATABASE_PATH = "local:#{ORIENT_PATH}/databases/tags"

KEEP_QUERY_RESULTS_FOR_DEBUGGING = false

if DATABASE == :Orient
  PATH_PREFIX = "#{ORIENT_BIN_PATH}/"
elsif DATABASE == :Postgres
  PATH_PREFIX = ''
elsif DATABASE == :Neo4j
  PATH_PREFIX = ''
end

QUERY_TO_RANGE = {
  1 => (1..200),
  2 => (1..18),
  3 => (1..200),
  4 => (1..8)
}

##### QUERIES

## Find all players on a given team
def query_1(team_number)
  case DATABASE
  when :Orient
    "SELECT EXPAND(out()) FROM (SELECT * FROM Tag WHERE name = \"Team #{team_number}\")"
  when :Postgres
    "SELECT * FROM tags where id IN (SELECT tag_relationships.child_id FROM tag_relationships WHERE parent_id = (SELECT tags.id FROM tags where name = 'Team #{team_number}'));"
  when :Neo4j
    "MATCH (t:Team {name: 'Team #{team_number}'})--(p:Player) RETURN p;"
  end
end

## Find all players in a League
def query_2(league_number)
  case DATABASE
  when :Orient
    "SELECT FROM (TRAVERSE * FROM (SELECT * FROM Tag WHERE name = \"League #{league_number}\") WHILE $depth <=3) WHERE type = \"Player\" LIMIT 100"
  when :Postgres
    "SELECT * FROM tags WHERE id IN (SELECT tag_relationships.child_id FROM tag_relationships WHERE parent_id IN (SELECT tags.id FROM tags WHERE tags.id IN (SELECT tag_relationships.child_id FROM tag_relationships WHERE parent_id IN (SELECT tags.id FROM tags WHERE id IN (SELECT tag_relationships.child_id FROM tag_relationships WHERE parent_id = (SELECT tags.id FROM tags WHERE name = 'League #{league_number}'))))));"
  when :Neo4j
    "MATCH (t:Team {name: 'League #{league_number}'})-[*..3]-(p:Player) RETURN p;"
  end
end

## Find the division a player belongs in
def query_3(player_number)
  case DATABASE
  when :Orient
    "SELECT FROM (TRAVERSE * FROM (SELECT * FROM Tag WHERE name = \"Player #{player_number}\") WHILE $depth <= 2) WHERE type = \"Division\""
  when :Postgres
    "SELECT * FROM tags WHERE id = (SELECT tag_relationships.parent_id FROM tag_relationships WHERE child_id = (SELECT tags.id FROM tags WHERE tags.id IN (SELECT tag_relationships.parent_id FROM tag_relationships WHERE child_id IN (SELECT tags.id FROM tags WHERE name = 'Player #{player_number}'))));"
  when :Neo4j
    "MATCH (p:Player {name: 'Player #{player_number}'})-[*..2]-(d:Division) RETURN d;"
  end
end

## Find all the tags in a group
def query_4(group_number)
  case DATABASE
  when :Orient
    "TRAVERSE * FROM (SELECT * FROM Tag WHERE name = \"Group #{group_number}\") WHILE $depth <=1 LIMIT 200;"
  when :Postgres
    "SELECT * FROM tags WHERE id IN (SELECT tag_relationships.child_id FROM tag_relationships WHERE parent_id = (SELECT tags.id FROM tags WHERE name = 'Group #{group_number}'));"
  when :Neo4j
    "MATCH (g:Group {name: 'Group #{group_number}'})--(t) RETURN t;"
  end
end

#### GENERATE THE QUERIES

(1..4).each do |query_number|
  File.open("#{PATH_PREFIX}#{DATABASE}_query_#{query_number}", 'w') do |file|
    case DATABASE
    when :Orient
      file.write("connect #{ORIENT_DATABASE_PATH} admin admin\n")
    when :Postgres
      file.write("\\connect tags_benchmarking\n\\timing\n")
    when :Neo4j
      file.write("")
    end
  end
end

(1..4).each do |query_number|
  QUERY_TO_RANGE[query_number].each do |indx|
    File.open("#{PATH_PREFIX}#{DATABASE}_query_#{query_number}", 'a') do |file|
      query_str = self.send("query_#{query_number}".to_sym, indx)
      file.puts query_str
    end
  end
end

### EXECUTE QUERIES AND PARSE THE RESULTS

(1..4).each do |query_number|
  case DATABASE
  when :Postgres
    total_time = `psql -p #{POSTGRES_PORT} < #{DATABASE}_query_#{query_number} > #{DATABASE}_query_#{query_number}_result; cat #{DATABASE}_query_#{query_number}_result | grep 'Time: ' | awk '{print $2}' | awk '{s+=$1} END {print s}'`.chomp.to_f
  when :Orient
    total_time = `cd #{ORIENT_BIN_PATH}; ./console.sh #{DATABASE}_query_#{query_number} > #{DATABASE}_query_#{query_number}_result; cat #{DATABASE}_query_#{query_number}_result | grep 'executed in' | awk '{print $7}' | awk '{s+=$1} END {print s}'`.chomp.to_f
  when :Neo4j
    total_time = `neo4j-shell < #{DATABASE}_query_#{query_number} > #{DATABASE}_query_#{query_number}_result; cat #{DATABASE}_query_#{query_number}_result | grep 'ms' | awk '{print $1}' | awk '{s+=$1} END {print s}'`.chomp.to_f
  end
  num_of_trials = QUERY_TO_RANGE[query_number].count
  average_time = total_time / num_of_trials.to_f
  if DATABASE == :Orient
    time_unit = 'secs'
  elsif DATABASE == :Postgres
    time_unit = 'millisecs'
  elsif DATABASE == :Neo4j
    time_unit = 'millisecs'
  end

  `rm #{DATABASE}_query_#{query_number}`
  `rm #{DATABASE}_query_#{query_number}_result` unless KEEP_QUERY_RESULTS_FOR_DEBUGGING

  puts "#{DATABASE} Query #{query_number} took an average of #{average_time.round(5)} #{time_unit} over #{num_of_trials} trials" 
end
