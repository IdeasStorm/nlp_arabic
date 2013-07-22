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