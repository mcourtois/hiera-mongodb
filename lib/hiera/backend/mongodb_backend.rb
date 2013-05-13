require 'mongo'

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
        end

        return answer
      end
    end
  end
end
