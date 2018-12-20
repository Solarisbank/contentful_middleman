module ContentfulMiddleman
  module LocalData
    class SyncFile < LocalData::File
      class << self
        def thor=(thor)
          @thor = thor
        end

        def thor
          @thor || LocalData::File.thor
        end
      end

      def initialize(data, path, adapter, remove: false)
        @id       = data.get(:id)
        @meta     = {
          content_type: data.get(:_meta).get(:content_type_id),
          updated_at:   data.get(:_meta).get(:updated_at),
        }
        @data     = data.to_yaml
        @path     = path
        @adapter  = adapter
        @remove   = remove
      end

      def sync_data
        {
          content_type: @meta[:content_type],
          updated_at:   @meta[:updated_at],
        }
      end

      def write
        # TODO: maybe check if interactive or not?
        if @remove
          @adapter.repository.drop(@id)
          self.class.thor.remove_file(local_data_file_path, nil, {force: true})
        else
          @adapter.repository.store(@id, sync_data)
          self.class.thor.create_file(local_data_file_path, nil, {force: true}) { @data }
        end
      end
    end
  end
end
