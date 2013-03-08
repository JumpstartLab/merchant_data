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

    def prepare_database
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

      test('.find_by_last_name')
      last_name = Customer.group(:last_name).having('COUNT(id) > 1').sample.last_name
      first_names = Customer.where(:last_name => last_name).map(&:first_name)
      data('last_name', last_name)
      data('first_names', first_names.join(', '))

      test('.find_all_by_first_name')
      first_name = Customer.group(:first_name).having('COUNT(id) > 1').sample.first_name
      data('first_name', first_name)
      data('count', Customer.where(:first_name => first_name).count)

      subheader('Relationships')
      test('#invoices')
      customer = Customer.random
      data('customer ID', customer.id)
      data('count', customer.invoices.count)

      subheader('Business Intelligence')

      test('setup')
      customer = Transaction.group(:invoice_id).having('COUNT(id) > 1').sample.invoice.customer
      data('customer ID', customer.id)

      test('#transactions')
      data('count', customer.transactions.count)

      test('#favorite_merchant')
      data('name', customer.favorite_merchant.name)
    end

    def report_merchants
      header('Merchant')

      subheader('Searching')

      test('.find_by_name')
      data('name', Merchant.random.name)

      test('.find_all_by_name')
      name = Merchant.group(:name).having('COUNT(id) > 1').sample.name
      data('name', name)
      data('count', Merchant.where(:name => name).count)

      subheader('Relationships')

      test('setup')
      merchant = Merchant.random
      data('name', merchant.name)

      test('#items')
      data('count', merchant.items.count)
      data('an item', merchant.items.sample.name)

      test('#invoices')
      data('count', merchant.invoices.count)
      customer = merchant.invoices.where(:status => 'shipped').sample.customer
      data('a customer', customer.last_name)

      subheader('Business Intelligence')

      test('.revenue(date)')
      date = Invoice.random.created_at.to_date
      data('date', format_date(date))
      data('revenue', Merchant.revenue(date))

      test('.most_revenue(3)')
      most_revenue = Merchant.most_revenue(3)
      data('first', most_revenue.first.name)
      data('last', most_revenue.last.name)

      test('.most_items(5)')
      most_items = Merchant.most_items(5)
      data('first', most_items.first.name)
      data('last', most_items.last.name)

      test('#revenue without a date')
      merchant = Merchant.group(:name).having('COUNT(id) = 1').sample
      data('name', merchant.name)
      data('revenue', merchant.revenue)

      test('#revenue with a date')
      merchant = Merchant.group(:name).having('COUNT(id) = 1').sample
      data('name', merchant.name)
      date = merchant.invoices.sample.created_at
      data('date', format_date(date))
      data('revenue', merchant.revenue(date))

      test('#favorite_customer')
      merchant = Merchant.random
      favorite = merchant.favorite_customer
      data('name', merchant.name)
      data('customer first_name', favorite.first_name)
      data('customer last_name', favorite.last_name)

      test('#customers_with_pending_invoices')
      merchant = Merchant.group(:name).having('COUNT(id) = 1').sample
      data('name', merchant.name)
      pending = merchant.customers_with_pending_invoices
      data('count', pending.count)
      data('a last name', pending.map(&:last_name).sample)
    end

    def report_transactions
      header('Transactions')

      subheader('Searching')

      test('.find_by_credit_card_number')
      transaction = Transaction.random
      data('transaction ID', transaction.id)
      data('credit card #', transaction.credit_card_number)

      test('.find_all_by_result')
      data('count', Transaction.where(:result => 'success').count)

      subheader('Relationships')

      test('#invoice')
      transaction = Transaction.random
      data('transaction ID', transaction.id)
      data('customer ID', transaction.invoice.customer.id)
    end

    def report_invoice_items
      header('Invoice Items')

      subheader('Searching')

      test('.find_by_item_id')
      item = InvoiceItem.random
      data('invoice item ID', item.id)

      test('.find_all_by_quantity')
      data('quantity', 10)
      data('count', InvoiceItem.where(:quantity => 10).count)

      subheader('Relationships')
      test('setup')
      invoice_item = InvoiceItem.random
      data('invoice item ID', invoice_item.id)
      test('#item')
      data('name', invoice_item.item.name)
    end

    def report_extensions_to_invoice
      header('Extension: Invoice')

      test('.pending')
      data('invoice ID', Invoice.pending.sample.id)

      test('.average_revenue')
      data('amount', Invoice.average_revenue)

      test('.average_revenue(date)')
      date = Invoice.random.created_at.to_date
      data('date', date)
      data('amount', Invoice.average_revenue(date))

      test('.average_items')
      data('count', Invoice.average_items)

      test('.average_items(date)')
      date = Invoice.random.created_at.to_date
      data('date', date)
      data('count', Invoice.average_items(date))
    end

    def report_extensions_to_customer
      header('Extension: Customer')
    end

    def report_extensions_to_merchant
      header('Extension: Merchant')
    end

  end

end
