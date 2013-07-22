class ActsAsDocumentMigration < ActiveRecord::Migration
  #TODO put migration logic here

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

end