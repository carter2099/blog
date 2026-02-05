require "test_helper"

class ReviewTest < ActiveSupport::TestCase
  test "valid review" do
    review = Review.new(
      title: "Dune",
      review_type: review_types(:book),
      rating: 5,
      author: "Frank Herbert",
      path: "app/reviews/dune.md"
    )

    assert review.valid?
  end

  test "rating must be between 0 and 5" do
    review = Review.new(
      title: "Dune",
      review_type: review_types(:book),
      rating: 5.1,
      author: "Frank Herbert",
      path: "app/reviews/dune.md"
    )

    assert_not review.valid?
  end

  test "rating can be a decimal" do
    review = Review.new(
      title: "Dune",
      review_type: review_types(:book),
      rating: 4.5,
      author: "Frank Herbert",
      path: "app/reviews/dune.md"
    )

    assert review.valid?
  end

  test "author is required for books" do
    review = Review.new(
      title: "Dune",
      review_type: review_types(:book),
      rating: 5,
      path: "app/reviews/dune.md"
    )

    assert_not review.valid?
    assert_includes review.errors[:author], "can't be blank"
  end

  test "author is not required for non-books" do
    review = Review.new(
      title: "Inception",
      review_type: review_types(:movie),
      rating: 4.5,
      path: "app/reviews/inception.md"
    )

    assert review.valid?
  end
end
