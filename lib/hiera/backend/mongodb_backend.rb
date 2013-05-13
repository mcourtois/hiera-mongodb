require 'mongo'

include Mongo

class Hiera
  module Backend
    class Mongodb_backend
      def initialize
        Hiera.debug("Hiera MongoDB backend starting")
      end

      def lookup(key, scope, order_override, resolution_type)
        answer = nil

        Hiera.debug("Looking up #{key} in MongoDB backend")

        Backend.datasources(scope, order_override) do |source|
          Hiera.debug("Looking for data source #{source}")

          document = collection.find_one({'source' => source.to_s, 'key' => key})
          if document
            new_answer = document['value']

            # for array resolution we just append to the array whatever
            # we find, we then goes onto the next file and keep adding to
            # the array
            #
            # for priority searches we break after the first found data item
            new_answer = Backend.parse_answer(new_answer, scope)
            case resolution_type
            when :array
              raise Exception, "Hiera type mismatch: expected Array and got #{new_answer.class}" unless new_answer.kind_of? Array or new_answer.kind_of? String
              answer ||= []
              answer << new_answer
            when :hash
              raise Exception, "Hiera type mismatch: expected Hash and got #{new_answer.class}" unless new_answer.kind_of? Hash
              answer ||= {}
              answer = Backend.merge_answer(new_answer,answer)
            else
              answer = new_answer
              break
            end
          end
        end

        return answer
      end

      private

      # Get a config key for this backend
      def self.config(key)
        Config[:mongodb][key.to_sym]
      end

      def self.collection
        if @database.nil?
          client = MongoClient.new(config :host)
          database = client.db(config :dbname)
          @database = database.collection(config :collection)
        end
      end

      def collection
        self.class.collection
      end
    end
  end
end
