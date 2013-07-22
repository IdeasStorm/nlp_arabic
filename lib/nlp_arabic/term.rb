class Term < ActiveRecord::Base
  attr_accessible :doc_freq, :word
	set_primary_key :word

  has_many :freq_term_in_doc, :foreign_key => "word"
end
