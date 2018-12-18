module ContentfulMiddleman
  module LocalData
    class DeletedFile < File
      def write
        # TODO: maybe check if interactive or not?
        self.class.thor.remove_file(local_data_file_path, nil, {force: true})
      end
    end
  end
end
