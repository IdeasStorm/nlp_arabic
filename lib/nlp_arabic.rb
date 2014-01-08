require 'nlp_arabic/arabic_stemmer'
require 'nlp_arabic/arabic_wordnet'
require 'nlp_arabic/acts_as_document'
require 'nlp_arabic/freq_term_in_doc'
require 'nlp_arabic/rank_weight'
require 'nlp_arabic/term'

module NlpArabic
  require 'railtie' if defined?(Rails)
end