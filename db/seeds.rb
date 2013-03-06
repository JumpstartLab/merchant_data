def create_merchant(name = nil)
  options = name ? {:name => name} : {}
  merchant = Fabricate(:merchant, options)

  rand(1..50).times do
    Fabricate(:item, :merchant => merchant)
  end
end

99.times { create_merchant }
create_merchant(Merchant.random.name)

exit

1000.times do
  customer = Fabricate(:customer)

  rand(0..10).times do
    merchant = Merchant.random
    time = Time.now - (rand(1..504).hours)
    invoice = Fabricate(:invoice, :merchant   => merchant,
                                  :customer   => customer,
                                  :created_at => time,
                                  :updated_at => time)
    rand(1..8).times do
      item = merchant.items.random
      invoice.invoice_items.create(:item => item, :quantity => rand(1..10), :unit_price => item.unit_price, :created_at => time, :updated_at => time)
    end
    if rand(5) < 4
      Fabricate(:transaction, :invoice => invoice)
    else
      rand(3).times do
        Fabricate(:transaction, :invoice => invoice, :result => "failed")
      end
      if rand(5) < 4
        Fabricate(:transaction, :invoice => invoice)
      end
    end
  end
end
