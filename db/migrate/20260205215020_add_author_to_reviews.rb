class AddAuthorToReviews < ActiveRecord::Migration[8.1]
  def change
    add_column :reviews, :author, :string
  end
end
