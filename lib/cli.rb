require 'fileutils'

module MerchantData
  class CLI
    def self.generate
      load_app
      Generator.new.run
      report
    end

    def self.report
      load_app
      DataModel.new.report
    end

    def self.load_app
      puts "Loading rails environment. Bear with me here."
      require File.expand_path("../../config/environment", __FILE__)
    end
  end

  class Generator
    def run
      puts "Not really running right now"
      exit(1)
      clean_up_tmp_dir
      bundle
      prepare_database
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

    def export
      puts "Exporting data to 'tmp/*.csv'"
      Exporter.export_tables_to_csv
    end
  end

  class DataModel
    def report
      report_items
      exit
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
      puts
      puts '*' * 80
      puts title.center(80)
      puts '*' * 80
    end

    def subheader(title)
      puts
      puts " #{title} ".center(80, '-')
    end

    def test(name)
      puts
      puts name
    end

    def data(title, value)
      print "#{title}: ".rjust(30)
      puts value
    end

    def format_date(date)
      date.strftime('%a, %e %b %Y')
    end

    def report_items
      header('Item')
      subheader('Searching')

      test('.find_by_unit_price')
      item = Item.group(:unit_price).having('COUNT(id) = 1').sample
      price = BigDecimal.new(item.unit_price) / 100
      data("price", price)
      data("name", item.name)

      test('.find_all_by_name')
      item = Item.group(:name).having('COUNT(id) > 1').sample
      data('name', item.name)
      data('count', Item.where(:name => item.name).count)

      subheader('Relationships')

      test('setup')
      data('name', item.name)
      test('#invoice_items')
      item = Item.group(:name).having('COUNT(id)=1').sample
      data('count', item.invoice_items.count)
      test('#merchants')
      data('name', item.merchant.name)

      subheader('Business Intelligence')

      test('.most_revenue(5)')
      top5 = Item.most_revenue(5)
      data('first', top5.first.name)
      data('last', top5.last.name)

      test('.most_items(37)')
      most = Item.most_items(37)
      data('most[1]', most[1])
      data('last', most.last)

      test('#best_day')
      item = Item.group(:name).having('COUNT(id)=1').sample
      data('name', item.name)
      data('date', format_date(item.best_day))
    end

    def report_invoices
      header('Invoice')

      subheader('Searching')
      test('shipped')
      data('count', Invoice.where(:status => 'shipped').count)

      subheader('Relationships')
      test('setup')
      invoice = Transaction.group(:invoice_id).having('COUNT(id) > 1').sample.invoice

      data('invoice ID', invoice.id)
      test('#transactions')
      data('count', invoice.transactions.count)
      test('#items')
      data('count', invoice.items.count)
      data('an item', invoice.items.sample.name)
      test('#customer')
      data('first_name',invoice.customer.first_name)
      data('last_name',invoice.customer.last_name)
      test('#invoice_items')
      data('count', invoice.invoice_items.count)
      data('an item', invoice.invoice_items.sample.item.name)
    end

    def report_customers
      header('Customer')
      subheader('Searching')
      subheader('Relationships')
      subheader('Business Intelligence')
    end

    def report_merchants
      header('Merchant')
      subheader('Searching')
      subheader('Relationships')
      subheader('Business Intelligence')
    end

    def report_transactions
      header('Transactions')
      subheader('Searching')
      subheader('Relationships')
      subheader('Business Intelligence')
    end

    def report_invoice_items
      header('Invoice Items')
      subheader('Searching')
      subheader('Relationships')
      subheader('Business Intelligence')
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
