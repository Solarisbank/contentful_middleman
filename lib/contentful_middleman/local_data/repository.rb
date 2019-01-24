require 'yaml'

module ContentfulMiddleman
  module LocalData
    class Repository
      class << self
        attr_accessor :base_path

        def exists_for?(space)
          ::File.exist?(path(space))
        end

        def path(space)
          ::File.join(base_path, "#{space}-repository.yaml")
        end
      end

      def initialize(space)
        @space  = space
        @data  = {}
        load if self.class.exists_for?(space)
      end

      attr_reader :updated_at

      def load
        yaml = ::YAML.load(::File.read(path))
        @updated_at     = yaml[:updated_at]
        @data           = yaml[:data]
        @last_sync_url  = yaml[:next_sync_url]
      end

      def changed?
        @last_sync_url != @next_sync_url
      end

      def next_sync_url
        @next_sync_url || @last_sync_url
      end

      def next_sync_url=(url)
        @next_sync_url = url
        @updated_at = Time.now.iso8601
      end

      def store(key, data)
        @data[key] = data
      end

      def content_type_for(key)
        @data.fetch(key, {}).fetch(:content_type)
      end

      def read(key, locale = nil)
        filename = ::File.join(self.class.base_path, @space.to_s, content_type_for(key).to_s, "#{key}.yaml")
        if ::File.exist?(filename)
          ::File.read(filename)
        else
          nil
        end
      end

      def entry(key, locale = nil)
        ::YAML.load(read(key, locale))
      end

      def drop(key)
        @data.delete(key)
      end

      def to_yaml
        {
          updated_at:     @updated_at,
          next_sync_url:  next_sync_url,
          data:           @data.compact,
        }.to_yaml
      end

      def write!
        ::File.open(path, 'w') { |file| file.write(self.to_yaml) }
        @last_sync_url = @next_sync_url
      end

      def write
        changed? && write!
      end

      def path
        self.class.path(@space)
      end
     end
  end
end
