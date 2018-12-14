module ContentfulMiddleman
  class ImportTask
    def initialize(space_name, content_type_names, content_type_mappers, contentful)
      @space_name           = space_name
      @content_type_names   = content_type_names
      @content_type_mappers = content_type_mappers
      @changed_local_data   = false
      @contentful           = contentful
      @use_camel_case       = @contentful.options.client_options.fetch(:use_camel_case, false)
      @use_sync             = @contentful.options[:use_sync]
    end

    def run
      old_identifier = if @use_sync
        ContentfulMiddleman::SyncUrl.read_for_space(@space_name)
      else
        ContentfulMiddleman::VersionHash.read_for_space(@space_name)
      end

      LocalData::Store.new(local_data_files, @space_name).write

      new_identifier = if @use_sync
        ContentfulMiddleman::SyncUrl.read_for_space(@space_name)
      else
        ContentfulMiddleman::VersionHash.write_for_space_with_entries(@space_name, entries, @use_camel_case)
      end

      @changed_local_data = new_identifier != old_identifier
    end

    def changed_local_data?
      @changed_local_data
    end

    def entries
      @entries ||= @contentful.entries
    end

    def file_name(content_type_name, entry)
      entry_id = entry.sys.key?(:id) ? entry.sys[:id] : entry.id
      File.join(@space_name, content_type_name, entry_id.to_s)
    end

    def with_sync
      @sync = if (sync_url = ContentfulMiddleman::SyncUrl.read_for_space(@space_name))
        @contentful.client.sync(sync_url)
      else
        @contentful.client.sync(initial: true)
      end
      yield @sync
      ContentfulMiddleman::SyncUrl.write_for_space(@space_name, @sync.next_sync_url)
    end

    private
    def local_data_files
      content_type_key = if @use_camel_case
                           :contentType
                         else
                           :content_type
                         end

      if @use_sync
        sync_entries(content_type_key)
      else
        map_entries(content_type_key)
      end
    end

    def sync_entries(content_type_key)
      entries = []
      with_sync do |sync|
        sync.each_item do |entry|
          if entry.is_a? Contentful::DeletedEntry
            content_type_mapper_class = @content_type_mappers.fetch(entry.sys[content_type_key].id, nil)
            next unless content_type_mapper_class

            entries << LocalData::DeletedFile.new(entry.id)
          elsif entry.is_a? Contentful::Entry
            entries << map_single_entry(entry, content_type_key)
          end
        end
      end
      entries.compact
    end

    def map_entries(content_type_key)
      entries.map do |entry|
        map_single_entry(entry, content_type_key)
      end.compact
    end

    def map_single_entry(entry, content_type_key)
      content_type_mapper_class = @content_type_mappers.fetch(entry.sys[content_type_key].id, nil)
      return unless content_type_mapper_class

      content_type_name = @content_type_names.fetch(entry.sys[content_type_key].id).to_s
      context = ContentfulMiddleman::Context.new

      content_type_mapper = content_type_mapper_class.new(entries, @contentful.options)
      content_type_mapper.map(context, entry)

      LocalData::File.new(context.to_yaml, file_name(content_type_name, entry))
    end
  end
end
