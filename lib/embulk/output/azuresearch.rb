module Embulk
  module Output

    require 'time'
    require_relative 'azuresearch/client'

    class Azuresearch < OutputPlugin
      Plugin.register_output("azuresearch", self)

      def self.transaction(config, schema, count, &control)
        # configuration code:
        task = {
           'endpoint'     => config.param('endpoint',     :string),
           'api_key'      => config.param('api_key',      :string),
           'search_index' => config.param('search_index', :string),
           'column_names' => config.param('column_names', :string),
           'key_names'    => config.param('key_names',    :string, :default => nil),
        }
        Embulk.logger.info "Azuresearch output transaction start"
        # param validation
        raise ConfigError, 'no endpoint' if task['endpoint'].empty?
        raise ConfigError, 'no api_key' if task['api_key'].empty?
        raise ConfigError, 'no search_index' if task['search_index'].empty?
        raise ConfigError, 'no column_names' if task['column_names'].empty?

        @search_index = task['search_index']
        @column_names = task['column_names'].split(',')
        @key_names = task['key_names'].nil? ? @column_names : task['key_names'].split(',')
        raise ConfigError, 'NOT match keys number: column_names and key_names' if @key_names.length != @column_names.length

        # resumable output:
        # resume(task, schema, count, &control)

        # non-resumable output:
        task_reports = yield(task)
        Embulk.logger.info "Azuresearch output finished. Task reports = #{task_reports.to_json}" 
        next_config_diff = {}
        return next_config_diff
      end

      def self.add_documents_to_azuresearch(documents)
        begin
          res = @client.add_documents(@search_index, documents)
          @successnum += documents.length
          puts res
        rescue Exception => ex
          Embulk.logger.error { "UnknownError: '#{ex}', documents=>" + documents.to_json }
        end
      end

      #def self.resume(task, schema, count, &control)
      #  task_reports = yield(task)
      #
      #  next_config_diff = {}
      #  return next_config_diff
      #end

      # init is called in initialize(task, schema, index)
      def init
        # initialization code:
        Embulk.logger.info "Azuresearch output init"
        @start_time = Time.now
        @recordnum = 0
        @successnum = 0
        
        @client=AzureSearch::Client::new( task['endpoint'], task['api_key'] )
      end

      def close
      end

      # called for each page in each task
      def add(page)
        # output code:
        documents = []
        page.each do |record|
          hash = Hash[schema.names.zip(record)]
          document = {}
          @column_names.each_with_index do|k, i|
            document[k] = values[i]
          end
          documents.push(document)
          @recordnum += 1
          if documents.length >= AzureSearch::MAX_DOCS_PER_INDEX_UPLOAD
            add_documents_to_azuresearch(documents)
            documents = []
          end
        end
        if documents.length > 0
            add_documents_to_azuresearch(documents)
        end
      end

      def finish
        Embulk.logger.info "AzureSearch output finish"
        @finish_time = Time.now
      end

      def abort
      end

      def commit
        Embulk.logger.info "AzureSearch output commit"
        elapsed_time = @finish_time - @start_time
        task_report = {
          "total_records" => @recordnum,
          "success" => @successnum,
          "skip_or_error" => (@recordnum - @successnum),
          "elapsed_time" => elapsed_time,
        }
        return task_report
      end
    end

  end
end
