class RandomCustomerWithNoPendingInvoicesQuery

  def result
    Customer.find_by_sql(sql).first
  end

  private

  def sql
    <<-SQL
      SELECT c.* FROM customers c
      LEFT JOIN (
        SELECT customer_id FROM invoices i
        LEFT JOIN (
          SELECT invoice_id
          FROM transactions
          WHERE result='success'
          GROUP BY invoice_id
        ) as t
        ON i.id=t.invoice_id
        WHERE t.invoice_id IS NULL
      ) AS pending
      ON pending.customer_id=c.id
      WHERE pending.customer_id IS NULL
      ORDER BY RANDOM()
      LIMIT 1
    SQL
  end

end
