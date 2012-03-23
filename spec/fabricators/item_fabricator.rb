Fabricator(:item) do 
  name{ ["Item", Faker::Lorem.words(2).collect{|w| w.capitalize}].join(" ")}
  description{ Faker::Lorem.paragraph }
  unit_price{ rand(50..100000) }
end