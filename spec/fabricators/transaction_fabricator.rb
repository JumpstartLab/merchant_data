Fabricator(:transaction) do 
  credit_card_number { Faker::CreditCard.number(:visa) }
  credit_card_expiration_date { Faker::CreditCard.expiration_date }
  result { "success" }
end