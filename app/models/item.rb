class Item < ActiveRecord::Base
  has_many :invoice_items
  belongs_to :merchant
end
