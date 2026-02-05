require "test_helper"

class ReviewTest < ActiveSupport::TestCase
  test "valid review" do
    review = Review.new(
      title: "Dune",
      review_type: "Books",
      rating: 5,

      path: "app/reviews/dune.md"
    )

    assert review.valid?
  end

  test "rating must be between 0 and 5" do
    review = Review.new(
      title: "Dune",
      review_type: "Books",
      rating: 5.1,

      path: "app/reviews/dune.md"
    )

    assert_not review.valid?
  end

  test "rating can be a decimal" do
    review = Review.new(
      title: "Dune",
      review_type: "Books",
      rating: 4.5,

      path: "app/reviews/dune.md"
    )

    assert review.valid?
  end
end
