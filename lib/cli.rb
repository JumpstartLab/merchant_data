require 'fileutils'

module MerchantData
  class CLI
    def self.generate
      Generator.new.run
    end
  end

  class Generator
    def run
      clean_up_tmp_dir
      bundle
      prepare_database
      load_app
      export
    end

    private

    def clean_up_tmp_dir
      FileUtils.rm_rf Dir.glob('tmp/*.csv')
      begin
        FileUtils.mkdir 'tmp'
      rescue Errno::EEXIST
        # that's OK, then
      end
    end

    def execute(command)
      puts "Running #{command}"
      system command
    end

    def bundle
      execute "bundle install"
    end

    def prepare_databes
      [
        "bundle exec rake db:drop",
        "bundle exec rake db:create",
        "bundle exec rake db:migrate",
        "bundle exec rake db:seed"
      ].each do |command|
        execute command
      end
    end

    def load_app
      puts "Loading rails environment. Bear with me here."
      require File.expand_path("../../config/environment", __FILE__)
    end

    def export
      puts "Exporting data to 'tmp/*.csv'"
      Exporter.export_tables_to_csv
    end
  end

end
