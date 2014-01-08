module NlpArabic
  module ActsAsDocument
    extend ActiveSupport::Concern

    @@registered_classes = Array.new

    module ClassMethods
      def acts_as_document(options={})
        cattr_accessor :acts_as_document_field,:root_terms
        self.acts_as_document_field = options[:on] || :title
        ActsAsDocument.register_class self.name
        include ActsAsDocument::LocalInstanceMethods
        extend ActsAsDocument::DocumentClassMethods
      end
    end

    module DocumentClassMethods

      #TO get root of words in arabic from db or WordNetArabic
      def get_root_words (words)
        all_terms = []
        words.each do |w|
          term = ArabicStemmer.get_instance.format_sentence(w)
          if term != "" and !term.nil?
            all_terms << term
          end
        end
        #To save root of words in db for improve performance
        #  	word.each do |w|
        #  		temp = RootTerms.find(w)
        #  		if temp.nil?
        # get word's root
        #r_w = get_root_term w
        #RootTerms.create(:word => w, :root => r_w)
        #  			end
        #  		elseif (!temp.root.nil?)
        #  			r_w = temp.root
        #  		end
        #  		all_terms << r_w
        #  	end #for word.each do |w|
        return all_terms
      end

      #To calculate tf (or term frequency of words) >> tf_w = f_w / max {f_w}
      def calculate_term_frequencies(terms)
        tf = {}
        max_frequency_of_terms = 0
        terms.each do |term|
          if !tf[term].nil?
            tf[term] += 1
          else
            tf[term] = 1
          end
          if tf[term] > max_frequency_of_terms
            max_frequency_of_terms = tf[term]
          end
        end

        tf.each_pair { |k,v| tf[k] = (0.5 + (( 0.5 * v.to_f) / max_frequency_of_terms))  }
        return tf
      end

      #To get df (or document frequency) of terms in all documents
      def document_freq_of_terms(terms)
        df = {}
        terms.uniq.each do |t|
          term = Term.find_by_word(t)
          if term.nil?
            df[t] = 0
          else
            df[t] = term.doc_freq
          end
        end
        return df
      end

      #To calculate weights vector of query
      def weights (tf,syn_hash=nil)
        w = {}
        docs_count = self.count
        df = self.document_freq_of_terms(tf.keys)
        tf.each_pair { |term,freq|
          w[term] = (freq *  Math.log(docs_count.to_f / (1+ df[term]) ))
          if !syn_hash.nil?
            if !syn_hash[term].nil?
              w[term] *= syn_hash[term]
            end
          end
        }
        return w
      end

      #To get lenght vector of weights >> |w|
      def lenght_vector (weights)
        lenght = 0
        weights.each_pair { |t,w|
          lenght += ( w * w)
        }
        return Math.sqrt(lenght)
      end

      #To find  similarity between tow vector >> sim(v1,v2) = sum {v1[t]*v2[t]} / |v1|*|v2|
      def sim (v1, v2)
        sum = 0
        v1.each_pair { |t,w|
          if !v2[t].nil?
            sum += (v1[t]*v2[t])
          end
        }

        l1 = lenght_vector(v1)
        l2 = lenght_vector(v2)
        return sum / (l1 * l2)
      end

      # Similarity docs by query
      def old_similarity (query,num=0,synonyms=true,docs=nil)
        sims = {}
        syn_hash = {}
        terms_q = self.get_root_words(query.split)
        if synonyms
          terms_q.each do |t|
            syns = ArabicStemmer.get_instance.get_synonyms(t)
            if !syns.nil?
              syn_hash.merge!(syns)
            end
          end
          terms_q << syn_hash.keys
          terms_q = terms_q.join(" ").split.uniq
        end
        tf_q = self.calculate_term_frequencies(terms_q)
        w_q = self.weights(tf_q,syn_hash)
        
        docs = self.all if docs.nil?
        docs.each do |doc|
          temp = self.sim(w_q, doc.weights)
          if temp > 0
            sims[doc] = temp
          end
        end
        return Hash[sims.sort_by{|k, v| v}.reverse].first ((num ==0)? sims.count : num)
      end

      def similarity (query,doc,syn_hash)
        tf_q = self.calculate_term_frequencies(query)
        w_q = self.weights(tf_q,syn_hash)
        
        return self.sim(w_q, doc.weights)
      end

    # Similarity docs by query
      def search_query (query,num=0,synonyms=true,docs=nil)
        res = {}
        syn_hash = {}
        terms_q = self.get_root_words(query.split)

        if synonyms
          terms_q.each do |t|
            syns = ArabicStemmer.get_instance.get_synonyms(t)
            if !syns.nil?
              syn_hash.merge!(syns)
            end
          end
          terms_q << syn_hash.keys
          terms_q = terms_q.join(" ").split.uniq
        end

        docs = self.all if docs.nil?
        docs.each do |doc|
          sim = similarity(terms_q,doc,syn_hash)     
          rank = rank_docs(terms_q,doc)
          res[doc] = sim + rank unless (sim+rank) == 0
        end

        return Hash[res.sort_by{|k, v| v}.reverse].first ((num ==0)? res.count : num)
      end

      # Rank docs by query
      def rank_docs (words,doc)
        count_action_words = {}

        words.each do |w|
          count_action = 0
          RankWeight.where(:word => w).map { |e| count_action += e.action_freq }
          count_action_words[w] = count_action
        end
        # To get all rank weights of all words
        rank_words_doc = RankWeight.where(:doc_id => doc.id,:word => words)
        weights = 0.0 # weights all words of this doc
        words.each do |w|
          temp = rank_words_doc.find_by_word(w)
          # To get rank weight this word in this doc
          weights += (temp.action_freq.to_f / count_action_words[w]) unless temp.nil?
        end
        return weights / words.count
      end

    end

    module LocalInstanceMethods

      #attr_accessible :root_terms
      def add_document
        #delete_document
        words = read_attribute(self.class.acts_as_document_field)
        words = words.split
        all_terms = self.class.get_root_words(words)

        if respond_to?('root_terms')
          self.update_column(:root_terms, all_terms.uniq.join(" ")) 
        end
        terms_freq = self.class.calculate_term_frequencies(all_terms)
        save_tf (terms_freq)

      end

      def add_rank_action (query, f = 1)
        #words = query.split
        words = self.class.get_root_words(query.split)
        words.each do |w|
          rank = RankWeight.where(:doc_id => self.id,:word => w).first
          if rank.nil?
            RankWeight.create(:doc_id => self.id, :word => w, :action_freq => f)
          else
            new_rank = rank.action_freq + f
            rank.update_attributes(:action_freq => new_rank)
          end
        end
      end
      #
      def delete_document
        doc = FreqTermInDoc.where(:doc_id => self.id)
        unless doc.empty?
          doc.each do |e|
            word = Term.find_by_word(e.word)
            new_freq = word.doc_freq - e.freq
            word.update_attributes(:doc_freq => new_freq)
            e.destroy
          end
        end
      end
#     def save_terms(terms)
#        terms.uniq.each do |t|
#          term = Term.find_by_word(t)
#          if term.nil?
#            Term.create(:word => t, :doc_freq => 1)
#          else
#            term.update_attributes(:doc_freq => term.doc_freq+1)
#          end
#        end
#      end

      def save_tf (hash_freq)
        all_words = FreqTermInDoc.where(:doc_id => self.id)
        
        hash_freq.each_pair {| term, freq |
          temp = all_words.where(:word => term).first
          word = Term.find_by_word(term)
          if !temp.nil?
            if temp.freq != freq
              term_freq = word.doc_freq - temp.freq + freq 
              word.update_attributes(:doc_freq => term_freq)
              temp.update_attributes(:freq => freq)
            end
          else
            FreqTermInDoc.create(:doc_id => self.id, :word => term, :freq => freq.to_f)
            if word.nil?
              Term.create(:word => term, :doc_freq => 1)
            else
              word.update_attributes(:doc_freq => word.doc_freq+1)
            end
          end
        }
      end

      def term_frequencies
        tf = {}
        table = FreqTermInDoc.where(:doc_id => self.id)
        table.each do |i|
          tf[i.word] = i.freq
        end
        return tf
      end

      def get_terms
        return self.root_terms if respond_to?('root_terms')
        self.terms 
      end
      #To get row terms of this document from Term table
      def terms
        terms = Term.joins("LEFT OUTER JOIN freq_term_in_docs ON freq_term_in_docs.word = terms.word AND freq_term_in_docs.doc_id = #{self.id}")
        #SELECT terms.* FROM terms
        #  INNER JOIN freq_term_in_docs On freq_term_in_docs.word = terms.word
        #  INNER JOIN transactions On freq_term_in_docs.doc_id = 1
        return terms
      end

      def document_freq_of_terms
        df = {}
        self.terms.uniq.each do |t|
          df[t.word] = t.doc_freq
        end
        return df
      end

      public
      def weights
        w = {}
        tf = self.term_frequencies
        docs_count = self.class.count
        df = self.document_freq_of_terms
        tf.each_pair { |term,freq|
          #w[term] = (freq *  Math.log(docs_count.to_f / (1+ df[term]) ))
          w[term] = (freq *  Math.log(docs_count.to_f / df[term] ))
        }
        return w
      end


      public
      def similarity_with_doc (doc2)
        w1 = self.weights
        w2 = doc2.weights
        return self.class.sim(w1, w2)
      end


      public
      def get_related_documents(num=5,docs=nil)
        res = {}
        #TODO !!!
        if docs.nil?
          docs = self.class.where(self.class.arel_table[:id].not_eq(self.id))
        end
        w = self.weights
        docs.each do |doc|
          doc_weights = doc.weights
          temp = self.class.sim(w, doc_weights)
          if temp > 0
            res[doc] = temp
          end
        end
        return Hash[res.sort_by{|k, v| v}.reverse].first num
      end

    end

    def self.registered_classes
      @@registered_classes
    end

    def self.register_class(class_object)
      @@registered_classes << class_object
    end
  end
end
ActiveRecord::Base.send :include, NlpArabic::ActsAsDocument