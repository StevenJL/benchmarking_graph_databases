module CreateGraph
  class Syntaxer
    attr_reader :database

    def initialize(database)
      @database = database
    end

    def create_vertex(klass, name, type)
      case database
      when :Orient
        "create vertex #{klass} content {name: \"#{name}\", type: \"#{type}\"}"
      when :Postgres
        "INSERT INTO tags (id, name, type) VALUES ('#{Counter.inc}', '#{name}', '#{type}');"
      when :Neo4j
        "CREATE (type:#{type} { name: '#{name}' });"
      end
    end

    def create_edge(name1, name2)
      case database
      when :Orient
        "create edge from (select from Tag where name = \"#{name1}\") to (select from Tag where name = \"#{name2}\")"
      when :Postgres
        "INSERT INTO tag_relationships (parent_id, child_id) VALUES ((SELECT tags.id FROM tags where name = '#{name1}'), (SELECT tags.id FROM tags where name = '#{name2}'));"
      when :Neo4j
        "MATCH (x), (y) WHERE x.name = '#{name1}' AND y.name = '#{name2}' CREATE (x)-[r:Parent]->(y);"
      end
    end

    class Counter
      @@current = 0
      def self.inc
        @@current = @@current + 1
      end
    end
  end
end
