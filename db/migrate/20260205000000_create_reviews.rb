class CreateReviews < ActiveRecord::Migration[8.0]
  def change
    create_table :reviews do |t|
      t.string :title, null: false
      t.string :review_type, null: false
      t.integer :rating, null: false
      t.date :reviewed_on, null: false
      t.string :path, null: false

      t.timestamps
    end

    add_index :reviews, :review_type
    add_index :reviews, :rating
    add_index :reviews, :reviewed_on
  end
end
