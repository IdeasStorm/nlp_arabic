class Transaction < ActiveRecord::Base
  attr_accessible :title, :root_terms
  acts_as_document
  after_save :add_document
end
