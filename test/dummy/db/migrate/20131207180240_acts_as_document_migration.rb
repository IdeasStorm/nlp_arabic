class ActsAsDocumentMigration < ActiveRecord::Migration
  #TODO put migration logic here

  def self.up
    create_table :terms do |t|
      t.string :word
      t.integer :doc_freq

      t.timestamps
    end
    add_index :terms, :word, :unique => true

    create_table :freq_term_in_docs do |t|
      t.integer :doc_id
      t.string :word
      t.float :freq

      t.timestamps
    end
    add_index :freq_term_in_docs, [:doc_id, :word], :unique => true
    
    puts "***********************************************************"
    puts NlpArabic::ActsAsDocument.registered_classes
    NlpArabic::ActsAsDocument.registered_classes.each do |c|
      add_column (c.downcase+"s").to_sym, :root_terms, :string
    end
  end

  def self.down
    drop_table :terms
    drop_table :freq_term_in_docs
  end

end