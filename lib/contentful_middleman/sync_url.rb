module ContentfulMiddleman
  class SyncUrl
    class << self
      def source_root=(source_root)
        @source_root = source_root
      end

      def read_for_space(space_name)
        syncfile_for_space = syncfilename(space_name)
        ::File.read(syncfile_for_space) if File.exist? syncfile_for_space
      end

      def write_for_space(space_name, sync_url)
        File.open(syncfilename(space_name), 'w') { |file| file.write(sync_url) }

        syncfilename(space_name)
      end

      private
        def syncfilename(space_name)
          ::File.join(@source_root, ".#{space_name}-sync-url")
        end
    end
  end
end
