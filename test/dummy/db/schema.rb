# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20140108153744) do

  create_table "freq_term_in_docs", :force => true do |t|
    t.integer  "doc_id"
    t.string   "word"
    t.float    "freq",       :default => 0.0
    t.datetime "created_at",                  :null => false
    t.datetime "updated_at",                  :null => false
  end

  add_index "freq_term_in_docs", ["doc_id", "word"], :name => "index_freq_term_in_docs_on_doc_id_and_word", :unique => true

  create_table "rank_weights", :force => true do |t|
    t.integer  "doc_id"
    t.string   "word"
    t.integer  "action_freq", :default => 0
    t.datetime "created_at",                 :null => false
    t.datetime "updated_at",                 :null => false
  end

  create_table "terms", :force => true do |t|
    t.string   "word"
    t.integer  "doc_freq",   :default => 0
    t.datetime "created_at",                :null => false
    t.datetime "updated_at",                :null => false
  end

  add_index "terms", ["word"], :name => "index_terms_on_word", :unique => true

  create_table "transactions", :force => true do |t|
    t.string   "title"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
    t.string   "root_terms"
  end

end
