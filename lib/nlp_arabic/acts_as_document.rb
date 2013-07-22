module NlpArabic
  module ActsAsDocument
    extend ActiveSupport::Concern

    @@registered_classes = Array.new

    module ClassMethods
      def acts_as_document(options={})
        cattr_accessor :acts_as_document_field
        self.acts_as_document_field = options[:on] || :title
        Documentize::ActsAsDocument.register_class self.class
        include Documentize::ActsAsDocument::LocalInstanceMethods
      end
    end

    module LocalInstanceMethods

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

      def get_related_documents
        #Todo add logic here
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