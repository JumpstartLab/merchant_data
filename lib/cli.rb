require 'fileutils'

module MerchantData
  class CLI
    def self.generate
      Generator.new.run
      report
    end

    def self.report
      DataModel.new.report
    end
  end

  class Generator
    def run
      puts "Not really running right now"
      exit(1)
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

  class DataModel
    def report
      report_items
      report_invoices
      report_customers
      report_merchants
      report_transactions
      report_invoice_items
      report_extensions_to_invoice
      report_extensions_to_customer
      report_extensions_to_merchant
    end

    def header(title)
      puts '*' * 80
      puts title.center(80)
      puts '*' * 80
    end

    def report_items
      header('Item')
    end

    def report_invoices
      header('Invoice')
    end

    def report_customers
      header('Customer')
    end

    def report_merchants
      header('Merchant')
    end

    def report_transactions
      header('Transactions')
    end

    def report_invoice_items
      header('Invoice Items')
    end

    def report_extensions_to_invoice
      header('Extension: Invoice')
    end

    def report_extensions_to_customer
      header('Extension: Customer')
    end

    def report_extensions_to_merchant
      header('Extension: Merchant')
    end

  end

end
