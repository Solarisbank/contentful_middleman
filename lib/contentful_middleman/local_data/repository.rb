require 'yaml'

module ContentfulMiddleman
  module LocalData
    class Repository
      class InconsistentDataError; end

      class << self
        attr_accessor :base_path

        def exists_for?(space)
          ::File.exist?(path(space))
        end

        def path(space)
          ::File.join(base_path, "#{space}-repository.yml")
        end
      end

      def initialize(space, mode = :sync)
        @space  = space
        @mode   = mode
        @index  = {}
      end

      attr_accessor :last_sync_hash

      def load
        yaml = ::YAML.load(File.read(path))
        fail InconsistentDataError,
          "The modes of stored and current data don't align." if yaml[:mode] != @mode
        fail InconsistentDataError,
          "Last sync URL does not match stored data." if yaml[:last_sync_hash] != @last_sync_hash
        @updated_at     = yaml[:updated_at]
        @index          = yaml[:index]
        @last_sync_hash = yaml[:last_sync_hash]
      end

      def store(key, data)
        @index[key] = data
      end

      def drop(key)
        @index.delete(key)
      end

      def to_yml
        {
          updated_at: @updated_at,
          mode: @mode,
          last_sync_hash: @last_sync_hash,
          index: @index.compact,
        }
      end

      def write
        ::File.open(path, 'w') { |file| file.write(self.to_yml) }
      end

      def path
        self.class.path(@space)
      end
     end
  end
end
