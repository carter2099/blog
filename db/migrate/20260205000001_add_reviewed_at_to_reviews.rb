class AddReviewedAtToReviews < ActiveRecord::Migration[8.0]
  def up
    add_column :reviews, :reviewed_at, :datetime

    Review.reset_column_information
    Review.find_each do |review|
      next unless review.respond_to?(:reviewed_on) && review.reviewed_on.present?

      review.update_columns(reviewed_at: review.reviewed_on.end_of_day)
    end

    remove_column :reviews, :reviewed_on
    change_column_null :reviews, :reviewed_at, false
    add_index :reviews, :reviewed_at
  end

  def down
    add_column :reviews, :reviewed_on, :date

    Review.reset_column_information
    Review.find_each do |review|
      next unless review.reviewed_at.present?

      review.update_columns(reviewed_on: review.reviewed_at.to_date)
    end

    remove_column :reviews, :reviewed_at
    change_column_null :reviews, :reviewed_on, false
    add_index :reviews, :reviewed_on
  end
end
