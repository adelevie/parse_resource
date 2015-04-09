module ParseResource
  class Base

    # Class methods
    class << self
      # Creates a RESTful resource for file uploads
      # sends requests to [base_uri]/files
      #
      def upload(file_instance, filename, options={})
        load_settings

        base_uri = "https://api.parse.com/1/files"

        #refactor to settings['app_id'] etc
        app_id     = @@settings['app_id']
        master_key = @@settings['master_key']

        options[:content_type] ||= 'image/jpg' # TODO: Guess mime type here.
        file_instance = File.new(file_instance, 'rb') if file_instance.is_a? String

        filename = filename.parameterize

        private_resource = RestClient::Resource.new "#{base_uri}/#{filename}", app_id, master_key
        private_resource.post(file_instance, options) do |resp, req, res, &block|
          return false if resp.code == 400
          return JSON.parse(resp) rescue {"code" => 0, "error" => "unknown error"}
        end
        false
      end
      alias_method :upload_file, :upload

      # Method takes in a filename string or file attributes hash and deletes
      # the file from Parse's AWS
      #   product = Product.find '12345'
      #   Product.delete_file(product.attributes['image'])
      #
      # Files are not deleted when record is deleted.
      # We have to manually send DELETE request to delete it.
      # The response is always 200 even if the file does not exist
      def self.delete_file(filename)
        if filename.is_a?(Hash) and filename.has_key?('name')
          filename = filename['name']
        end

        load_settings

        base_uri = "https://api.parse.com/1/files"
        app_id     = @@settings['app_id']
        master_key = @@settings['master_key']

        private_resource = RestClient::Resource.new "#{base_uri}/#{filename}", app_id, master_key
        private_resource.delete do |resp, req, res, &block|
          return resp.code == 200
        end
      end
    end

    # Returns true if info about attached file is present
    def has_attachment?(column: 'image')
      attributes[column.to_s].present?
    end

    # Allows uploads directly on the model
    # Accepts ActionDispatch::Http::UploadedFile file and optional column name
    # where the file will be saved to. You need to save model yourself
    def upload_file(file, column: 'image')
      return true unless file
      result = self.class.upload file.tempfile, file.original_filename, content_type: file.content_type
      if result
        send "#{column}=", {"name" => result["name"], "__type" => "File", "url" => result["url"]}
      else
        errors.add column, 'File upload failed'
        return false
      end
    end

    # Allows users to delete attached file directly from the model instance
    #   product = Product.find '12344'
    #   product.delete_file(column: 'image')
    def delete_file(column: 'image')
      unless attributes.keys.include? column.to_s
        raise ArgumentError, "Unknown column #{column} for #{self.class}"
      end
      self.class.delete_file attributes[column.to_s]
    end

  end
end