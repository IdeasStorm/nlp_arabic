class FreqTermInDoc < ActiveRecord::Base
  attr_accessible :doc_id, :freq, :word

  belongs_to :term, :foreign_key => "word"
  validates_uniqueness_of :doc_id, scope: :word
end
