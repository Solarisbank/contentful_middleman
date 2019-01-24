module ContentfulMiddleman
  module LocalData
    class File
      class << self
        def thor=(thor)
          @thor = thor
        end

        def thor
          @thor
        end
      end

      def initialize(data, path)
        @data = data
        @path = path
      end

      def write
        # TODO: maybe check if interactive or not?
        self.class.thor.create_file(local_data_file_path, nil, {force: true}) { @data }
      end

      def local_data_file_path
        base_path = LocalData::Store.base_path
        ::File.join(base_path, @path + ".yaml")
      end
    end
  end
end
