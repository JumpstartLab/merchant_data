class CustomerGeneratingMostRevenueQuery

  def result
    Customer.find_by_sql(sql).first
  end

  private

  def sql
    <<-SQL
    SELECT c.*
    FROM customers c
    INNER JOIN invoices i
    ON c.id=i.customer_id
    INNER JOIN
    (
      SELECT invoice_id, (quantity * unit_price) amount
      FROM invoice_items
    ) t
    ON i.id=t.invoice_id
    GROUP BY c.id
    ORDER BY SUM(t.amount) DESC
    LIMIT 1
    SQL
  end

end
