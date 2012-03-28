class Merchant < ActiveRecord::Base
  has_many :invoices
  has_many :items

  def customers
    invoices.map(&:customer)
  end

  def favorite_customer
    defaults_to_zero = Hash.new(0)

    totals = invoices.inject(defaults_to_zero) do |acc, i|
      acc[i.customer_id] += 1 unless i.pending?
      acc
    end

    id = totals.sort_by {|k, v| v}.reverse.first.first
    Customer.find_by_id id
  end

  def revenue(date=nil)
    @revenue       ||= {}
    @revenue[date] ||= begin
      invoices_of_interest = if date
        invoices.select{|i| i.updated_at.to_date == date}
      else
        invoices.all
      end
      invoices_of_interest.select{|i| !i.pending?}.inject(BigDecimal.new(0)) do |acc, i|
        acc + i.total
      end
    end
  end

  def self.revenue(date)
    all.map {|m| m.revenue(date) }.sum
  end

  def self.most_items(n)
    all.sort_by {|m| -m.items_sold }.first(n)
  end

  def self.most_revenue(n)
    all.sort.first(n)
  end

  def items_sold
    invoices.map(&:items_sold).sum
  end

  def <=>(o)
    (revenue <=> o.revenue) * -1
  end

  def customers_with_pending_invoices
    pending_invoices = invoices.select {|invoice| invoice.pending? }
    pending_invoices.map(&:customer)
  end
end
