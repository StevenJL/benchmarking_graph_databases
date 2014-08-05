module CreateGraph
  class CommandExecuter
    attr_reader :params, :filename

    def initialize(params)
      @params = params
      @filename = "#{params[:orient_path]}/bin/#{params[:database]}_insert_commands"
    end

    def generate
      File.open(filename, 'w') do |file|
        case params[:database]
        when :Orient
          file.write("connect local:#{params[:orient_path]}/databases/tags admin admin\n")
        when :Postgres
          file.write("\\connect tags_benchmarking\n")
        end
      end

      generate_tree
      generate_cycle
    end

    private

    def generate_tree
      syntaxer = CreateGraph::Syntaxer.new(params[:database])
      tree = params[:tree]

      File.open(filename, 'a') do |file|
        types = tree.keys << nil
        types.each_with_index do |type, index|
          return unless type
          parent = types[index-1]
          tree[type].times do |indx|
            file.puts create_vertex('Tag', "#{type} #{indx + 1}", "#{type}")
            next unless parent
            denom = (tree[type]/tree[parent])
            parent_index = ((indx+1)/denom.to_f).ceil
            file.puts syntaxer.create_edge("#{parent} #{parent_index}", "#{type} #{indx+1}")
          end
        end
      end
    end

    def generate_cycle
      syntaxer = CreateGraph::Syntaxer.new(params[:database])
      cycles = params[:cycles]

      File.open(filename, 'a') do |file|
        cycles.each do |group_index, array|
          file.puts syntaxer.create_vertex('Tag', "Group #{group_index}", 'Group')
          type, range = array
          range.each do |type_index|
            file.puts syntaxer.create_edge("Group #{group_index}", "#{type} #{type_index}")
          end
        end
      end
    end
  end
end
