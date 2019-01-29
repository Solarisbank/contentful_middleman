require 'contentful_middleman/local_data/repository'
require 'middleman-core/util/data'

module ContentfulMiddleman
  module LocalData
    class RepositoryExtension < ::Middleman::Extension
      class << self
        attr_reader :repository

        def add_repository(symbol, repo)
          @repository ||= {}
          @repository[symbol] = repo
        end
      end

      expose_to_application repository: :handler
      expose_to_config      repository: :handler
      expose_to_template    repository: :handler

      def initialize(app, options_hash=::Middleman::EMPTY_HASH, &block)
        super
      end

      def handler
        self
      end

      def repository
        ::Middleman::Util::EnhancedHash.new(self.class.repository)
      end

      def find(key)
        !(f = repository.values.find { |repo| repo.key?(key) }).nil? && f.entry(key)
      end

      def method_missing(symbol, *args, &block)
        if repository.keys.include?(symbol.to_s)
          repository[symbol]
        else
          super
        end
      end

      def respond_to?(symbol, include_all = false)
        repository.keys.include?(symbol) || super
      end
    end
  end
end

::Middleman::Extensions.register :repository, auto_activate: :before_configuration do
  ::ContentfulMiddleman::LocalData::RepositoryExtension
end
