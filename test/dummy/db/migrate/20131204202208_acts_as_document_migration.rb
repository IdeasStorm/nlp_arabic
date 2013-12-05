class ActsAsDocumentMigration < ActiveRecord::Migration
  #TODO put migration logic here

  def self.up
    create_table :terms do |t|
      t.string :word
      t.integer :doc_freq

      t.timestamps
    end

    create_table :freq_term_in_docs do |t|
      t.integer :doc_id
      t.string :word
      t.float :freq

      t.timestamps
    end
    #NlpArabic::ActsAsDocument.registered_classes.each do |c|
     # add_column c.downcase+"s",  :root_terms, :string
    #end
  end

  def self.down
    drop_table :terms
    drop_table :freq_term_in_docs
  end

end