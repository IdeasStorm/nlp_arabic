module Enumerable
  def divide_by
    result = Hash.new
    each do |o|
      i = yield(o)
      result[i] = [] if (result[i] == nil)
      result[i] << o
    end
    return result
  end
end
class ArabicStemmer
  def initialize(options=nil)
    @options =options || Hash.new
    @options[:folder_path] ||= File.dirname(__FILE__) + '/stemmer_files'
    self.load_files()
  end

  def reset

  end

  def load_files()
    # initiallizing data list
    @dicts = Hash.new
    files = Dir.glob(File.join(@options[:folder_path], "*"))

    # looping over data files
    files.each do |file|
      # getting file name only
      file_name = file.match(/.*\/(.*)\.txt/)[1]

      accumulator = ''
      # accumulating file contents
      File.open(file) do |io|
        accumulator << io.read
      end
      @dicts[file_name] = accumulator.split
    end

    # putting vowels into dictionary
    @dicts['letters'] = Hash.new
    @dicts['letters']['waw'] = "\u0648"
    @dicts['letters']['yah'] = "\u064a"
    @dicts['letters']['maksoura'] = "\u0649"
    @dicts['letters']['alif'] = "\u0627"
    @dicts['letters']['hamza'] = "\u0623"
    @dicts['letters']['waw_hamza'] = "\u0624"
    @dicts['letters']['yah_hamza'] = "\u0626"
    @dicts['letters']['line_hamza'] = "\u0621"
    @dicts['letters']['shadda'] = "\u0651"
    @dicts['letters']['madda'] = "\u0622"
    @dicts['letters']['under_hamza'] = "\u0622"
    @dicts['letters']['fa'] = "\u0641"
    @dicts['letters']['ain'] = "\u0639"
    @dicts['letters']['lam'] = "\u0644"

    c = @dicts['letters']
    # pre-loading
    # convert the patterns into regex
    @dicts['patterns'] = @dicts['tri_patt'].map do |pattern|
      regex_pattern = pattern.gsub(Regexp.new '['+c['fa']+c['ain']+c['lam']+']') do |letter|
        "(?<#{letter}>[[:alpha:]])"
      end
      pattern = "^#{regex_pattern}$" # putting line begin & end markers
    end


    # dividing parts by length
    prefixes_lists = @dicts['prefixes'].divide_by { |x| x.length }
    suffixes_lists = @dicts['suffixes'].divide_by { |x| x.length }
    definite_articles_lists = @dicts['definite_article'].divide_by { |x| x.length }

    @dicts['definite_article_pattern'] = []
    definite_articles_lists.each_pair do |i, v|
      @dicts['definite_article_pattern'][i]= "^(" + v.join('|') + ")" + "(?<word>[[:alpha:]]+)$"
    end

    @dicts['prefixes_patterns'] = []
    prefixes_lists.each_pair do |i, v|
      @dicts['prefixes_patterns'][i] = "^(" + v.join('|') + ")" + "(?<word>[[:alpha:]]+)$"
    end

    @dicts['suffixes_patterns'] = []
    suffixes_lists.each_pair do |i, v|
      @dicts['suffixes_patterns'][i] = "^(?<word>[[:alpha:]]+)" + "(" + v.join('|') + ")$"
    end

    puts 'dictionaries loaded.'
  end

  # Word Stemming

  def stem_word(word)
    new_word = word.clone
    new_word, status = process_two_letters(new_word) if (word.length == 2)
    new_word, status = process_three_letters(new_word) if (word.length == 3 && status != :root)
    new_word, status = process_four_letters(new_word) if (word.length == 4)
    new_word, status = check_patterns(new_word) if (status != :root)
    new_word, status = check_definite_article(new_word) if (status != :root)
    new_word, status = check_prefix_waw(new_word) if (status != :root && status != :stop_word)
    new_word, status = check_suffixes(new_word) if (status != :root && status != :stop_word)
    new_word, status = check_prefixes(new_word) if (status != :root && status != :stop_word)

    return [new_word, status]
  end

  def check_patterns(word)
    c = @dicts['letters']
    new_word = word.clone
    # returning hamza to alif
    if [c['hamza'], c['under_hamza'], c['madda']].include? word[0]
      new_word[0] = c['alif']
    end

    patterns = @dicts['patterns']

    #TODO solve limited regex problem with (ef3lal)
    i = 0
    # Matching Patterns to Verbs
    patterns.each do |pattern|
      new_word.match pattern do |verb|
        @last_word = word
        #return [word, :not_pattern] if word[-1] == c['yah'] and @dicts['tri_patt'][i][-1] == c['lam']
        @last_pattern_id = i
        new_word = verb[c['fa']] + verb[c['ain']] + verb[c['lam']] # concat fa & ain & lam
        new_word, status = process_three_letters(new_word)
        #TODO remove this if encountered any problem
        return [new_word, status] if status == :root
      end
      i += 1
    end

    return [word, :not_pattern]
  end

  def check_definite_article(word)
    new_word = word.clone
    status = :no_article_found

    # iterating bigger --> smaller articles
    3.downto 2 do |i|
      word.match @dicts['definite_article_pattern'][i] do |res|
        new_word, status = process_word(res['word'])
        return [new_word, status]
      end
    end

    return [new_word, status]
  end

  def check_prefixes(word)
    new_word = word.clone
    status = :no_prefix_found
    #TODO is 4 enough
    4.times do
      # iterating bigger --> smaller articles
      2.downto 1 do |i|
        new_word.match @dicts['prefixes_patterns'][i] do |res|
          new_word, status = process_word res['word'], false, true
          return [new_word, status] if status == :root
        end
      end
    end

    return [word, status]
  end

  def check_suffixes(word)
    new_word = word.clone
    #TODO is 4 enough
    4.times do
      # iterating bigger --> smaller articles
      3.downto 1 do |i|
        new_word.match @dicts['suffixes_patterns'][i] do |res|
          new_word, status = process_word res['word'], false, false
          return new_word, status if status == :root
        end
      end
    end

    return [word, :no_suffix_found]
  end

  def check_prefix_waw(word)
    if (word.length > 3) && word[0] == @dicts['letters']['waw']
      new_word = word.clone[1..-1]
      new_word, status = process_word new_word
      return [new_word, status]
    else
      return [word, :no_waw_found]
    end
  end

  def process_word(word, prefix=true, suffix=true)
    new_word = word.clone
    return [new_word, :stop_word] if is_stopword?(new_word)
    new_word, status = process_two_letters(new_word) if word.length == 2
    #TODO check elsif problem
    new_word, status = process_three_letters(new_word) if word.length == 3
    new_word, status = process_four_letters(new_word) if word.length == 4

    new_word, status = check_patterns(new_word) if (status != :root) && (word.length > 2)
    new_word, status = check_suffixes(new_word) if (status != :root) && (status != :stop_word) && suffix
    new_word, status = check_prefixes(new_word) if (status != :root) && (status != :stop_word) && prefix

    return new_word, status
  end

  # process a word that consists of 2 letters
  # it could have a missing vowel or it could have a missing duplicate letter "shadda"
  def process_two_letters(word)
    new_word = word.clone
    new_word, status = recover_duplicate_letter(new_word)

    # processing missing vowels
    new_word, status = recover_first_vowel(new_word) if status != :root
    new_word, status = recover_middle_vowel(new_word) if status != :root
    new_word, status = recover_last_vowel(new_word) if status != :root

    return [new_word, status]
  end

  def process_three_letters(word)
    c = @dicts['letters']
    new_word = word.clone
    # Check the first letter
    #TODO i've added madda
    if [c['alif'], c['waw_hamza'], c['yah_hamza'], c['madda']].include? word[0]
      new_word[0] = c['hamza']
    end

    # Check the last letter
    if [c['alif'], c['yah'], c['waw'], c['maksoura'], c['line_hamza'], c['yah_hamza']].include? word[2]
      new_word = word.clone[0..1]
      new_word, status = recover_last_vowel new_word
      return [new_word, status] if status == :root
      new_word = word.clone
    end

    # Check the middle letter
    if [c['alif'], c['yah'], c['waw'], c['yah_hamza']].include? word[1]
      new_word = word[0] + word[2]
      new_word[1] = c['hamza'] if (new_word[1] == c['line_hamza'])
      new_word, status = recover_middle_vowel new_word
      return [new_word, status] if status == :root
      new_word = word.clone
    end

    ##################################################################################

    if [c['waw_hamza'], c['yah_hamza']].include? word[1]
      new_word = word.clone
      new_word[1] = c['hamza']
      #TODO apply different logic
    end

    if word[2] == c['shadda']
      new_word = word[0..1] + word[1]
    end

    # no match
    if @dicts['tri_roots'].include? new_word
      return [new_word, :root]
    end

    return [word, :no_root]
  end

  def process_four_letters(word)
    if @dicts['quad_roots'].include? word
      return [word, :root]
    else
      return [word, :not_quad_root]
    end
  end

  # checks if the word has a missing duplicate letter and recovers it.
  def recover_duplicate_letter(word)
    if @dicts['duplicate'].include? word
      new_word = word.clone + word[-1]
      return [new_word, :root]
    end
    return [word, :no_duplicate]
  end

  def recover_first_vowel(word)
    if @dicts['first_waw'].include? word
      word = @dicts['letters']['waw'] + word
      return [word, :root]
    elsif @dicts['first_yah'].include? word
      word = @dicts['letters']['yah'] + word
      return [word, :root]
    else
      return [word, :no_first_vowel]
    end
  end

  def recover_middle_vowel(word)
    if @dicts['mid_waw'].include? word
      word = word[0] + @dicts['letters']['waw'] + word[-1]
      return [word, :root]
    elsif @dicts['mid_yah'].include? word
      word = word[0] + @dicts['letters']['yah'] + word[-1]
      return [word, :root]
    else
      return [word, :no_middle_vowel]
    end
  end

  def recover_last_vowel(word)
    ['alif', 'hamza', 'maksoura', 'yah'].each do |letter|
      if @dicts['last_' + letter].include? word
        word = word + @dicts['letters'][letter]
        return [word, :root]
      end
    end
    return [word, :no_last_vowel]
  end

  # Text Normalization

  # @param word [String]
  def format_word(word)
    new_word = remove_diacritics(word)
    new_word = remove_nonletter(new_word) # and punctuation
    if (is_strangeword? new_word)
      return { :result => new_word, :status => :strange_word, :pure_word => new_word}
    elsif (is_stopword? new_word)
      return { :result => new_word, :status => :stop_word, :pure_word => new_word}
    else
      stem_result = stem_word(new_word)

      if (stem_result[1] != :root)
        @last_word = stem_result[0]
        @last_pattern_id = -1
      elsif @last_pattern_id == nil
        @last_word = stem_result[0]
      end
      #return [stem_result, @last_pattern_id, @last_word].flatten
      return {
        :result => stem_result[0],
        :status => stem_result[1],
        :pattern => @last_pattern_id,
        #:pure_word  => @last_word
        :pure_word  => stem_result[0]
      }
    end
  end

  def remove_diacritics(word)
    word.tr @dicts['diacritics'].join(''), ''
  end

  def remove_triples(word)
    word += ' '
    count = 1
    old_ch = ''
    uniq_word = ''
    word.each_char do |ch|
      if old_ch == ch
        count+=1
      elsif old_ch != ch
        uniq_word += old_ch * count if count < 3
        uniq_word += old_ch if count >= 3
        count = 1
      end
      old_ch = ch
    end
    return uniq_word
  end

  def remove_nonletter(word)
    #TODO optimize this & remove other non-letter
    new_word = word.clone
    @dicts['punctuation'].each do |c|
      new_word.delete! c
    end
    new_word.gsub!(/\d+/, '')
    new_word.gsub!('ـ', '')
    
    #scan for duplicated words
    new_word = remove_triples(new_word)
    return new_word
  end

  def is_stopword?(word)
    @dicts['stopwords'].include? word
  end

  def is_strangeword?(word)
    @dicts['strange'].include?(word) or word.match(/[a-zA-z]/)
  end

  def format_sentence(sentence)
    result = sentence.split.map do |word|
      res = format_word(word)[:pure_word]
    end
    result.join ' '
  end

  def get_synonyms(word)
    word_result = format_word(word)
    results = ArabicWordnet.get_synonyms(word_result[:pure_word],false)
    if (results.count > 0)
      synonyms = Hash.new
      results.delete word_result[:pure_word]
      results.each do |w|
        result = format_word w
        if result[:pattern] == word_result[:pattern]
          synonyms[result[:pure_word]] = 1
        else
          synonyms[result[:pure_word]] = 0.8
        end
      end
      return synonyms
    else
      results = ArabicWordnet.get_synonyms(word_result[:result], true)
      if (results.count > 0)
        synonyms = Hash.new
        results.delete word_result[:pure_word]
        results.each do |w|
          result = format_word w
          if result[:pattern] == word_result[:pattern]
            synonyms[result[:pure_word]] = 0.8
          else
            synonyms[result[:pure_word]] = 0.1
          end
        end
        return synonyms
      end
    end
  end

  def self.test
    stemmer = ArabicStemmer.new
    text = File.read(File.dirname(__FILE__) + '/stemmer_files/test.txt')
    #text.split.each do |word|
    #  puts stemmer.format_sentence(word)
    #end
    puts stemmer.format_sentence text
  end
  @@instance = ArabicStemmer.new

  def self.get_instance
    @@instance
  end
end
