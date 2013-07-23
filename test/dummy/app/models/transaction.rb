class Transaction < ActiveRecord::Base
  attr_accessible :title
  acts_as_document
  after_save :add_document
end
