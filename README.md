### Benchmarking Graph Databases

Ruby scripts to create a large graph and store it in either Postgres, Orientdb, Neo4j, and Arangodb, and then run a bunch of queries to benchmark their performance.

### Usage

#### Config
Determine what kind of graph you want to build by modifying `config/graph.yml`.  Every graph can be decomposed into a tree with cycles.  

Also set up the database specific params like binary path, port, etc. in `config/orient.yml`.

#### Setup DB

    ./db_setup Orient # Set up the Orient database, for example
    ./db_setup Orient drop=true  # Set up but drop the existing one

#### Generate the Graph

    ./create_graph Postgres # Generate the graph in postgres, for example

#### Query the Graph

    ./query_graph Neo4j # Run the queries in neo4j





