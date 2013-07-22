module NlpArabic
  module ActsAsDocument
    extend ActiveSupport::Concern

    @@registered_classes = Array.new
    #TODO check it
    after_save :add_document

    module ClassMethods
      def acts_as_document(options={})
        cattr_accessor :acts_as_document_field
        self.acts_as_document_field = options[:on] || :title
        Documentize::ActsAsDocument.register_class self.class
        include Documentize::ActsAsDocument::LocalInstanceMethods
      end
    end

    module LocalInstanceMethods

      def add_document
        words = self.acts_as_document_field.split
        all_terms = self.get_root_words(words)
        #if self.has_attributes?('root_terms')
        if respond_to?('root_terms')
          self.update_attributes(:root_terms => all_terms.join(" "))
        end
        terms_freq = self.calculate_term_frequencies(all_terms)
        save_tf (terms_freq)
        save_term(all_terms)
      end

      def self.get_root_words (words)
        all_terms = []
        words.each do |w|
          term = ArabicStemmer.get_instance.format_sentence(w)
          if term != "" and !term.nil?
            all_terms << term
          end
        end
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
        return all_terms.uniq
      end

      private
      def self.calculate_term_frequencies(terms)
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

      private
      def save_terms(terms)
        terms.uniq.each do |t|
          term = Term.find_by_word(t)
          if term.nil?
            Term.create(:word => t, :doc_freq => 1)
          else
            term.update_attributes(:doc_freq => term.doc_freq+1)
          end
        end
      end

      private
      def save_tf (hash_freq)
        hash_freq.each_pair {| term, freq |
          FreqTermInDoc.create(:doc_id => self.id, :word => term, :freq => freq)
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

      #To get row terms of this document from Term table
      def terms
        terms = Term.joins('LEFT OUTER JOIN freq_term_in_docs ON freq_term_in_docs.word = terms.word AND freq_term_in_docs.doc_id = self.id')
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

      #To used it for query
      def self.document_freq_of_terms(terms)
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

      def weights
        w = {}
        tf = self.term_frequencies
        docs_count = self.class.count
        df = self.document_freq_of_terms
        tf.each_pair { |term,freq|
          w[term] = (freq *  Math.log(docs_count.to_f / (1+ df[term]) ))
          #w[term] = (freq *  Math.log(docs_count.to_f / df[term] ))
        }
        return w
      end

      def self.weights (tf,syn_hash=nil)
        w = {}
        docs_count = self.class.count
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

      private
      def self.lenght_vector (weights)
        lenght = 0
        weights.each_pair { |t,w|
          lenght += ( w * w)
        }
        return Math.sqrt(lenght)
      end

      private
      def self.sim (v1, v2)
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

      def similarity_with_doc (doc_id)
        #TODO !!
        doc2 = self.class.find(doc_id)
        w1 = self.weights
        w2 = doc2.weights
        return self.sim(w1, w2)
      end

      def self.similarity (query,num=0,synonyms=true)
        sims = {}
        syn_hash = {}
        terms_q = self.get_root_words(query.split) #return array
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
        #TODO !!
        docs = self.class.all
        docs.each do |doc|
          temp = self.sim(w_q, doc.weights)
          if temp > 0
            sims[doc] = temp
          end
        end
        return Hash[sims.sort_by{|k, v| v}.reverse].first ((num ==0)? sims.count : num)
      end

      def get_related_documents(num=5)
        res = {}
        #TODO !!!
        docs = self.class.where(self.class.arel_table[:id].not_eq(self.id))
        w = self.weights
        docs.each do |doc|
          doc_weights = doc.weights
          temp = self.sim(w, doc_weights)
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