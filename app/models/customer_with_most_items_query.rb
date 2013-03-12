class CustomerWithMostItemsQuery

  def result
    Customer.find_by_sql(sql).first
  end

  private

  def sql
    <<-SQL
    SELECT c.*
    FROM customers c
    INNER JOIN
    (
      SELECT i.customer_id, i.id invoice_id, COUNT(ii.id) items
      FROM invoices i
      INNER JOIN invoice_items ii
      ON ii.invoice_id=i.id
      GROUP BY i.id
    ) t
    ON c.id=t.customer_id
    GROUP BY c.id
    ORDER BY SUM(t.items) DESC
    LIMIT 1
    SQL
  end

end
