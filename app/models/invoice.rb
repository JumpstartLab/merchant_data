class Invoice < ActiveRecord::Base
  has_many :transactions
  has_many :invoice_items
  has_many :items, :through => :invoice_items
  belongs_to :merchant
  belongs_to :customer

  def self.pending
    sql = <<-SQL
    SELECT i.* FROM invoices i
    LEFT JOIN (
      SELECT invoice_id
      FROM transactions
      WHERE result='success'
      GROUP BY invoice_id
    ) as t
    ON i.id=t.invoice_id
    WHERE t.invoice_id IS NULL
    SQL

    find_by_sql(sql)
  end

  def self.revenue
    BigDecimal.new(revenue_in_cents) / 100
  end

  def self.revenue_in_cents(date = nil)
    sql = ""
    sql << "SELECT SUM(amount) "
    sql << "FROM ( "
    sql << "SELECT (unit_price * quantity) as amount "
    sql << "FROM invoice_items "
    sql << "WHERE date(created_at) = '#{date}'" if date
    sql << ") AS t"
    connection.select_value(sql)
  end

  def self.average_revenue(date = nil)
    BigDecimal.new(average_revenue_in_cents(date)) / 100
  end

  def self.average_items(date = nil)
    if date
      InvoiceItem.count_on(date) / count_on(date)
    else
      InvoiceItem.count / count
    end
  end

  def self.average_revenue_in_cents(date = nil)
    return 0 if count == 0
    n = date ? count_on(date) : count
    revenue_in_cents(date) / n
  end

  def self.count_on(date)
    where("date(created_at) = '#{date}'").count
  end

  def total
    BigDecimal.new(total_in_cents) / 100
  end

  def total_in_cents
    sql = "SELECT SUM(quantity * unit_price) total FROM invoice_items WHERE invoice_id=#{id}"
    connection.select_value sql
  end

  def items_sold
    invoice_items.map(&:quantity).sum
  end

  def pending?
    transactions.empty? || transactions.all?(&:failed?)
  end
end
