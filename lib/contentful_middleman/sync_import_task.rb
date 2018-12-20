require 'contentful_middleman/local_data/sync_file'

module ContentfulMiddleman
  class SyncImportTask < ImportTask
    def initialize(*args)
      super
      @sync_adapter = ContentfulMiddleman::SyncAdapter.new(@space_name, @contentful, @content_type_names)
    end

    def run
      LocalData::Store.new(local_data_files, @space_name).write
      @sync_adapter.repository.write
    end

    def changed_local_data?
      @sync_adapter.repository.changed?
    end

    def file_name(content_type_name, entry)
      entry_id = entry.sys.key?(:id) ? entry.sys[:id] : entry.id
      File.join(@space_name, content_type_name, entry_id.to_s)
    end

    def local_data_files
      content_type_key = if @use_camel_case
                           :contentType
                         else
                           :content_type
                         end

      entries = []
      @sync_adapter.update do |entry|
        next unless [Contentful::Entry, Contentful::DeletedEntry].include?(entry.class)

        content_type_mapper_class = @content_type_mappers.fetch(entry.sys[content_type_key].id, nil)
        next unless content_type_mapper_class

        content_type_name = @content_type_names.fetch(entry.sys[content_type_key].id).to_s
        context = ContentfulMiddleman::Context.new

        content_type_mapper = content_type_mapper_class.new(entry, @contentful.options)
        content_type_mapper.map(context, entry)

        if entry.is_a? Contentful::DeletedEntry
          entries << LocalData::SyncFile.new(context, file_name(content_type_name, entry), @sync_adapter, remove: true)
        elsif entry.is_a? Contentful::Entry
          entries << LocalData::SyncFile.new(context, file_name(content_type_name, entry), @sync_adapter)
        end
      end
      entries
    end
  end
end
