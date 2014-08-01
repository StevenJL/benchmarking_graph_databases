case DATABASE  
when :Orient
  db_setup_config = YAML.load_file('./config/orient.yml')
  ORIENT_PATH = db_setup_config["path"]
  DB_NAME = db_setup_config["databasename"]
  ORIENT_BIN_PATH = "#{ORIENT_PATH}/bin"
  ORIENT_DATABASE_PATH = "local:#{ORIENT_PATH}/databases/#{DB_NAME}"
  FILENAME = "#{ORIENT_BIN_PATH}/#{DATABASE}_#{DB_NAME}_inserts"
when :Postgres
  POSTGRES_PORT = '5432'
  FILENAME = "#{DATABASE}_tag_inserts"
when :Neo4j
  FILENAME = "#{DATABASE}_tag_inserts"
end
