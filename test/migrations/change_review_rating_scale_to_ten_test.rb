require "test_helper"
require Rails.root.join("db/migrate/20260829000000_change_review_rating_scale_to_ten")

class ChangeReviewRatingScaleToTenTest < ActiveSupport::TestCase
  test "doubles existing ratings and reverses cleanly" do
    review = Review.create!(
      title: "Inception",
      review_type: review_types(:movie),
      rating: 4
    )
    migration = ChangeReviewRatingScaleToTen.new

    migration.up

    assert_equal 8.0, review.reload.rating

    migration.down

    assert_equal 4.0, review.reload.rating
  end
end
