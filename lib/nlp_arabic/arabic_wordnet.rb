class ArabicWordnet < ActiveRecord::Base
  establish_connection "wordnet"
  
  ###
  ##  return array of synonyms of input word
  ##  output:
  ##    word: input word
  ##    root:
  ##      true  => the input word is a root
  ##      false => the input word is not a root
  ##  input:
  ##    array of synonyms not root words
  ###
  def self.get_synonyms(word, root)
    words = Array.new
    db = connection

    # If the input word is a root
    if (root)
      # Find the words in form table
      words = db.execute("SELECT Distinct w1.value
                        FROM words w1
                        INNER JOIN (SELECT w2.synsetid
                                    FROM words w2
                                    WHERE w2.wordid IN (SELECT f1.wordid
                                                        FROM forms f1
                                                        WHERE f1.value = '#{word}')) AS res
                        ON w1.synsetid = res.synsetid")
    end

    # If there are no result
    if (words.count < 1)
      # Find the words in words table
      words = db.execute("SELECT w1.value
                        FROM words w1
                          INNER JOIN words w2
                          ON w1.synsetid = w2.synsetid
                          AND w2.value = '#{word}'")

      # If there are no result
      if (words.count < 1)
        # Find the words in items table
        words = db.execute("SELECT w1.value
                          FROM words w1
                          INNER JOIN items t1
                          ON w1.synsetid = t1.itemid
                          AND t1.name = '#{word}'")
      end
    end
    # return flatten array
    words.collect {|word| word[0]}
  end
end