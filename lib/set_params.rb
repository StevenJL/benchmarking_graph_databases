case DATABASE
when :Orient
  ORIENT_PATH = '/Users/stevenli/releases/orientdb'
  ORIENT_BIN_PATH = "#{ORIENT_PATH}/bin"
  ORIENT_DATABASE_PATH = "local:#{ORIENT_PATH}/databases/tags"  
  FILENAME = "#{ORIENT_BIN_PATH}/#{DATABASE}_tag_inserts"
when :Postgres
  POSTGRES_PORT = '5432'
  FILENAME = "#{DATABASE}_tag_inserts"
when :Neo4j
  FILENAME = "#{DATABASE}_tag_inserts"
end
