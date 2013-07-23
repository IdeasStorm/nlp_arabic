require 'nlp_arabic'
require 'rails'
module NlpArabic
  class Railtie < Rails::Railtie
    railtie_name :nlp_arabic

    rake_tasks do
       Dir[File.join(File.dirname(__FILE__),'tasks/*.rake')].each { |f| load f }
    end
  end
end