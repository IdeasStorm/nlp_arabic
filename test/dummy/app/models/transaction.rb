class Transaction < ActiveRecord::Base
  attr_accessible :title
  acts_as_document

end
