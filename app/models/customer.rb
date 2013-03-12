class Customer < ActiveRecord::Base
  has_many :invoices

  def self.most_items
    CustomerWithMostItemsQuery.new.result
  end

  def self.most_revenue
    CustomerGeneratingMostRevenueQuery.new.result
  end

  def self.random_with_no_pending_invoices
    RandomCustomerWithNoPendingInvoicesQuery.new.result
  end

  def self.random_with_pending_invoices
    Invoice.pending.sample.customer
  end

  def self.random_with_transactions
    Customer.find_by_sql(with_transactions_sql).first
  end

  def self.random_with_transactions_sql
    <<-SQL
    select c.* from customers c
    inner join invoices i on c.id=i.customer_id
    inner join transactions t on i.id=t.invoice_id
    order by random()
    limit 1
    SQL
  end

  def pending_invoices
    invoices.select(&:pending?)
  end

  def days_since_activity
    (Date.today - most_recent_transaction.created_at.to_date).to_i
  end

  def most_recent_transaction
    transactions.sort_by(&:created_at).last
  end

  def transactions
    invoices.map(&:transactions).flatten
  end

  def successful_transactions
    transactions.select{|txn| !txn.failed? }
  end

  def favorite_merchants
    merchant_transactions = successful_transactions.group_by {|t| t.invoice.merchant_id }
    merchant_transactions.sort_by {|m_id, txns| -txns.count}
  end

  def favorite_merchant
    merchant_with_most = favorite_merchants.first
    Merchant.find_by_id(merchant_with_most.first)
  end

  def self.more_than_one
    id = all.map(&:favorite_merchant_helper).compact.find{|m, c, id| c > 1}.last
    find id
  end

  def favorite_merchant_helper
    merchant_transactions = transactions.group_by {|t| t.invoice.merchant_id }
    merchant_with_most = merchant_transactions.sort_by {|m_id, txns| -txns.count}.first
    return nil unless merchant_with_most
    [Merchant.find(merchant_with_most.first), merchant_with_most.last.count, id]
  end
end
