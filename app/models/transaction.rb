class Transaction < ActiveRecord::Base
  belongs_to :invoice

  def successful?
    result == "success"
  end

  def failed?
    !successful?
  end
end
