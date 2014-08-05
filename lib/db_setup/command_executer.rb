module DbSetup
  class CommandExecuter
    attr_reader :database, :params, :command_array, :filename
    def initialize(params)
      @database = params[:database]
      @params = params
      @command_array = []
      @filename = "#{params[:orient_path]}/bin/#{database}_setup_commands"
    end

    def generate
      case database
      when :Orient
        @command_array << "drop database local:#{params[:orient_db_path]} admin admin" if ARGV.include?('drop=true')
        @command_array << "create database local:#{params[:orient_db_path]} admin admin local"
        @command_array << "connect local:#{params[:orient_db_path]} admin admin"
        @command_array = command_array + params[:setup_model]
      when :Postgres
      when :Neo4j
      end
      return self
    end

    def execute
      # if the file doesn't exist, create it
      # if it does exist, empty it
      `echo '' > #{filename}`

      # write the comamnds
      File.open(filename, 'a') do |file|
        command_array.each do |cmd|
          file.puts cmd
        end
      end

      `#{params[:orient_path]}/bin/console.sh < #{filename}`
      `rm #{filename}`
    end
  end
end
