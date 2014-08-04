class Params
  # Takes a database and returns all the relevant 
  # benchmarking params (db shell path, port, graph structure) 
  # in a hash.

  attr_reader :database

  def initialize(database)
    @database = database
  end

  def generate
    output_hash = {}
    case database
    when :Orient
      orient_config_yaml = YAML.load_file("#{ROOT}/config/orient.yml")
      output_hash[:orient_path] = orient_config_yaml["path"]
      output_hash[:orient_db_path] = "#{orient_config_yaml['path']}/databases/#{orient_config_yaml['databasename']}"
    when :Postgres
      postgres_config_yaml = YAML.load_file("#{ROOT}/config/postgres.yml")
      output_hash[:postgres_port] = postgres_config_yaml['port']
    when :Neo4j

    end

    # Add tree and cycle
    output_hash[:tree] = YAML.load_file("#{ROOT}/config/graph.yml")["Tree"]
    output_hash[:cycles] = cycle_generator(1000, output_hash[:tree].keys.last, output_hash[:tree].values.last)
    output_hash
  end

  private
  def cycle_generator(num_of_cycles, name_of_vertices, num_of_vertices)
    output_hash = {}
    width = (num_of_vertices/num_of_cycles.to_f).floor
    (1..num_of_cycles).to_a.each_slice(width).to_a.each_with_index do |sub_array, index|
      output_hash[index] = [name_of_vertices, sub_array]
    end
    output_hash
  end  
end
