class InvoiceItem < ActiveRecord::Base
  belongs_to :invoice
  belongs_to :item

  def pending?
    invoice.pending?
  end

  def revenue
    return BigDecimal.new(0) if pending?

    BigDecimal.new(unit_price) / 100 * quantity
  end
end
