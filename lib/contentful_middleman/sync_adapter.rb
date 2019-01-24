require 'contentful_middleman/local_data/repository'

module ContentfulMiddleman
  class SyncAdapter
    def initialize(space_name, contentful, content_type_names)
      @space_name         = space_name
      @contentful         = contentful
      @content_type_names = content_type_names
    end

    def repository
      @repository ||= LocalData::Repository.new(@space_name, @contentful.options.content_types)
      @repository
    end

    def update(&block)
      @sync = if repository.next_sync_url
        @contentful.client.sync(repository.next_sync_url)
      else
        @contentful.client.sync(initial: true)
      end
      @sync.each_item(&block)
      repository.next_sync_url = @sync.next_sync_url
    end
  end
end
