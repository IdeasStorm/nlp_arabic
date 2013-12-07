class AddRootTermsToTransaction < ActiveRecord::Migration
  def change
    add_column :transactions, :root_terms, :string
  end
end
