class Invoice < ActiveRecord::Base
  has_many :transactions
  has_many :invoice_items
  has_many :items, :through => :invoice_items
  belongs_to :merchant
  belongs_to :customer

  def total
    sql = "select SUM(ii.quantity * ii.unit_price) total from invoice_items ii inner join invoices i on ii.invoice_id=i.id where i.id=#{id}"
    value = connection.select_value sql
    BigDecimal.new(value)/100
  end

  def items_sold
    invoice_items.map(&:quantity).sum
  end

  def pending?
    transactions.empty? || transactions.all?(&:failed?)
  end
end
