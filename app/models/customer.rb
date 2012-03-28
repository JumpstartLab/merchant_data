class Customer < ActiveRecord::Base
	has_many :invoices

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
