class Item < ActiveRecord::Base
  has_many :invoice_items
  belongs_to :merchant

  def self.most_revenue(n)
    all.sort.first(n)
  end

  def self.most_items(n)
    all.sort_by {|i| -i.total_sold }.first(n)
  end

  def best_day
    invoice_items.group_by {|ii| ii.updated_at.to_date}.sort_by {|date, items| -items.map(&:quantity).sum}.first
  end

  def total_revenue
    total = invoice_items.inject(0) do |acc, ii|
      acc + ii.quantity * ii.unit_price
    end
    BigDecimal.new(total)
  end

  def total_sold
    total = invoice_items.inject(0) do |acc, ii|
      acc + ii.quantity
    end
    BigDecimal.new(total)
  end

  def <=>(o)
    (total_revenue <=> o.total_revenue) * -1
  end
end
