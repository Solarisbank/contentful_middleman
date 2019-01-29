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

      DATA_FILE_MATCH = /^(.*?)[\w-]+\.(ya?ml)$/.freeze

      def initialize(space, content_types = [])
        @space          = space
        @data           = {}
        @content_types  = content_types
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
        entry = @data[key]
        if not entry
          warn "could not find content type for #{key}"
          nil
        else
          entry.fetch(:content_type)
        end
      end

      def key?(key)
        @data.has_key?(key)
      end

      def read(key, locale = nil)
        if content_type = content_type_for(key)
          filename = ::File.join(self.class.base_path, @space.to_s, content_type.to_s, "#{key}.yaml")
          if ::File.exist?(filename)
            ::File.read(filename)
          else
            ''
          end
        else
          ''
        end
      end

      def entry(key, locale = nil)
        Entry.new(key, self, locale)
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

      def method_missing(symbol, *args, &block)
        if @content_types.include?(symbol)
          content_path = ::File.join(self.class.base_path, @space.to_s, symbol.to_s)
          entries = ::Dir.entries(content_path).select do |f|
            ::File.file?(::File.join(content_path, f)) && f =~ DATA_FILE_MATCH
          end
          entries = entries.reduce({}) do |hsh, file|
            yaml = ::YAML.load(::File.read(::File.join(content_path, file)))
            hsh[yaml[:id]] = Entry.new(yaml[:id], self, nil, yaml)
            hsh
          end
          entries
        else
          super
        end
      end

      def respond_to?(symbol, include_all = false)
        @content_types.include?(symbol) || super
      end
    end

    class Entry
      attr_reader :id
      def initialize(id, repository, locale = nil, raw = nil)
        @id           = id
        @repository   = repository
        @locale       = locale
        @raw          = raw if raw
      end

      def content_type
        @content_type ||= @repository.content_type_for(@id)
      end

      def raw
        if @repository
          @raw ||= ::YAML.load(@repository.read(@id, @locale))
        end
        @raw || {}
      end

      def fields
        @fields ||= raw.reject { |i, _| [:id, :_meta].include?(i) }.reduce({}) do |hsh, (k, v)|
          if v.is_a?(Array) && v.any? { |i| i.is_a?(Hash) && i.keys.include?(:id)}
            hsh[k] = v.map { |i| @repository.content_type_for(i[:id]) ? self.class.new(i[:id], @repository, @locale) : nil}.compact
          else
            hsh[k] = v
          end
          hsh
        end
        @fields
      end

      def meta
        ::Middleman::Util::EnhancedHash.new(raw[:_meta])
      end

      def method_missing(symbol, *args, &block)
        if raw.keys.include?(symbol)
          fields[symbol]
        else
          super
        end
      end

      def respond_to?(symbol, include_all = false)
        raw.reject { |i, _| [:id, :_meta].include?(i) }.include?(symbol)
      end
    end
  end
end
