# encoding: utf-8

require 'sequel'

###
## Class to use arabic wordnet to get synonyms words
###
class ArabicWordnet

  ###
  ##  return array of synonyms of input word
  ##  input:
  ##    word: input word
  ##    root:
  ##      true  => the input word is a root
  ##      false => the input word is not a root
  ##  output:
  ##    array of synonyms not root words
  ###
  def self.get_synonyms(word, root)
    words = Array.new
    result = Array.new
    db = Sequel.connect('sqlite://../../db/ArabicWordnet.sqlite')

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
      result = words.collect {|w| w[0]}
    end

    # If there are no result
    if (result.count < 1)
      # Find the words in words table
      words = db.execute("SELECT w1.value
                        FROM words w1
                          INNER JOIN words w2
                          ON w1.synsetid = w2.synsetid
                          AND w2.value = '#{word}'")
      result = words.collect {|w| w[0]}


      # If there are no result
      if (result.count < 1)
        # Find the words in items table
        words = db.execute("SELECT w1.value
                          FROM words w1
                          INNER JOIN items t1
                          ON w1.synsetid = t1.itemid
                          AND t1.name = '#{word}'")
        result = words.collect {|w| w[0]}
      end
    end
    # return flatten array
    result
  end
  
  ###
  ##  return array of synonyms of input word
  ##  input:
  ##    word: input word
  ##    root:
  ##      true  => the input word is a root
  ##      false => the input word is not a root
  ##  output:
  ##    array of synonyms root words
  ###
  def self.get_synonyms_root(word, root)
    words = Array.new
    result = Array.new

    db = Sequel.connect('sqlite://../../db/ArabicWordnet.sqlite')

    # If the input word is a root
    if (root)
      # Find the words in form table
      words = db.execute("SELECT Distinct f1.value
                          FROM forms f1
                          WHERE f1.wordid IN
                                     (SELECT Distinct w1.wordid
                                      FROM words w1
                                      INNER JOIN (SELECT w2.synsetid
                                                  FROM words w2
                                                  WHERE w2.wordid IN 
                                                          (SELECT f2.wordid
                                                            FROM forms f2
                                                            WHERE f2.value = '#{word}')) AS res
                                      ON w1.synsetid = res.synsetid)")
      result = words.collect {|w| w[0]}
    end

    # If there are no result
    if (result.count < 1)
      # Find the words in words table
      words = db.execute("SELECT Distinct f1.value
                          FROM forms f1
                          WHERE f1.wordid IN
                                     (SELECT w1.wordid
                                      FROM words w1
                                      INNER JOIN words w2
                                      ON w1.synsetid = w2.synsetid
                                      AND w2.value = '#{word}')")
      result = words.collect {|w| w[0]}

      # If there are no result
      if (result.count < 1)
        # Find the words in items table
        words = db.execute("SELECT Distinct f1.value
                            FROM forms f1
                            WHERE f1.wordid IN
                                        (SELECT w1.wordid
                                        FROM words w1
                                        INNER JOIN items t1
                                        ON w1.synsetid = t1.itemid
                                        AND t1.name = '#{word}')")
        result = words.collect {|w| w[0]}
      end
    end
    # return flatten array
    result
  end
end