class ChangeReviewRatingToFloat < ActiveRecord::Migration[8.1]
  def change
    change_column :reviews, :rating, :float, null: false
  end
end
