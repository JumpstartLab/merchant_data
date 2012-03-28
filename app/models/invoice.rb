class Invoice < ActiveRecord::Base
  has_many :transactions
  has_many :invoice_items
  has_many :items, :through => :invoice_items
  belongs_to :merchant
  belongs_to :customer

  def total
    invoice_items.inject(BigDecimal.new(0)) do |acc, ii|
      acc + ii.revenue
    end
  end

  def items_sold
    invoice_items.map(&:quantity).sum
  end

  def pending?
    transactions.empty? || transactions.all?(&:failed?)
  end
end
