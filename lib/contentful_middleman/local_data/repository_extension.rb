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
      expose_to_config    repository: :repository
      expose_to_template  repository: :repository

      def initialize(app, options_hash=::Middleman::EMPTY_HASH, &block)
        super
      end

      def repository
        ::Middleman::Util::EnhancedHash.new(self.class.repository)
      end
    end
  end
end

::Middleman::Extensions.register :repository, auto_activate: :before_configuration do
  ::ContentfulMiddleman::LocalData::RepositoryExtension
end
