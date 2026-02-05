class RemoveReviewedDateFromReviews < ActiveRecord::Migration[8.1]
  def change
    remove_column :reviews, :reviewed_at, :datetime if column_exists?(:reviews, :reviewed_at)
    remove_column :reviews, :reviewed_on, :date if column_exists?(:reviews, :reviewed_on)
  end
end
