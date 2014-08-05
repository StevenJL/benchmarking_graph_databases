class Params
  # Takes a database and returns all the necessary
  # params (db shell path, port, graph structure) 
  # in a nice hash.

  attr_reader :database

  def initialize(arg_array)
    raise "Please specify database" if arg_array.empty?
    @database = arg_array[0].to_sym
  end

  def generate
    output_hash = {:database => database}
    case database
    when :Orient
      orient_config_yaml = YAML.load_file("#{ROOT}/config/orient.yml")
      output_hash[:orient_path] = orient_config_yaml["path"]
      output_hash[:orient_db_path] = "#{orient_config_yaml['path']}/databases/#{orient_config_yaml['database_name']}"
      output_hash[:setup_model] = orient_config_yaml["setup_model"]
    when :Postgres
      postgres_config_yaml = YAML.load_file("#{ROOT}/config/postgres.yml")
      output_hash[:postgres_port] = postgres_config_yaml['port']
    when :Neo4j
    end

    # Add tree and cycle
    output_hash[:tree] = YAML.load_file("#{ROOT}/config/graph.yml")["Tree"]
    num_of_cycles = YAML.load_file("#{ROOT}/config/graph.yml")["NumOfCycles"]["Count"]
    output_hash[:cycles] = cycle_generator(num_of_cycles, output_hash[:tree].keys.last, output_hash[:tree].values.last)
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
