class Item < ActiveRecord::Base
  has_many :invoice_items
  belongs_to :merchant

  def self.most_revenue(n)
    joins(:invoice_items).group('invoice_items.item_id').order('SUM(invoice_items.quantity * invoice_items.unit_price) DESC').limit(n)
  end

  def self.most_items(n)
    joins(:invoice_items).group('items.id').order('COUNT(invoice_items.id) DESC').limit(n)
  end

  def best_day
    ii_by_date = invoice_items.group_by do |ii|
      ii.invoice.created_at.to_date
    end
    ii_by_date.sort_by do |date, items|
      -items.map(&:quantity).sum
    end.first.first
  end

  def total_revenue
    @total_revenue ||= begin
      invoice_items.inject(BigDecimal.new(0)) do |acc, ii|
        acc + ii.revenue
      end
    end
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
