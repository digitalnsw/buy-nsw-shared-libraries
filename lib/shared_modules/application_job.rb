module SharedModules
  class RetryError < RuntimeError; end

  class ApplicationJob < ActiveJob::Base
    # At the moment everything gets queued in the same queue
    queue_as ENV.fetch('MAILER_QUEUE_NAME', :default)

    rescue_from Exception do |exception|
      if exception.is_a? RetryError
        raise exception
      else
        Airbrake.notify_sync exception
      end
    end

    protected

    def download_file(document)
      if remote_file?
        directory = Rails.root.join('tmp', 'scan', document.to_param)
        FileUtils.mkdir_p(directory)

        path = directory.join("FILE_CONTENT")
        File.open(path, 'w+') do |f|
          f.write(open(document.document.url).read.force_encoding('UTF-8'))
        end

        path.to_s
      else
        document.document.file.path
      end
    end

    def remote_file?
      CarrierWave::Uploader::Base.storage != CarrierWave::Storage::File
    end
  end
end
