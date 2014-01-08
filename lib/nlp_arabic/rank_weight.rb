class RankWeight < ActiveRecord::Base
  attr_accessible :doc_id, :action_freq, :word

  belongs_to :term, :foreign_key => "word"
end
