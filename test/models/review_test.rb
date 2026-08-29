require "test_helper"

class ReviewTest < ActiveSupport::TestCase
  test "valid review" do
    review = Review.new(
      title: "Dune",
      review_type: review_types(:book),
      rating: 10,
      author: "Frank Herbert",
      path: "app/reviews/dune.md"
    )

    assert review.valid?
  end

  test "valid review without path" do
    review = Review.new(
      title: "Dune",
      review_type: review_types(:book),
      rating: 10,
      author: "Frank Herbert"
    )

    assert review.valid?
  end

  test "rating must be between 0 and 10" do
    review = Review.new(
      title: "Dune",
      review_type: review_types(:book),
      rating: 10.1,
      author: "Frank Herbert"
    )

    assert_not review.valid?
  end

  test "rating can be a decimal" do
    review = Review.new(
      title: "Dune",
      review_type: review_types(:book),
      rating: 9.5,
      author: "Frank Herbert"
    )

    assert review.valid?
  end

  test "formats integer and decimal ratings out of 10" do
    review = Review.new(rating: 8)

    assert_equal "8/10", review.formatted_rating

    review.rating = 9.5

    assert_equal "9.5/10", review.formatted_rating
  end

  test "author is required for books" do
    review = Review.new(
      title: "Dune",
      review_type: review_types(:book),
      rating: 10
    )

    assert_not review.valid?
    assert_includes review.errors[:author], "can't be blank"
  end

  test "author is not required for non-books" do
    review = Review.new(
      title: "Inception",
      review_type: review_types(:movie),
      rating: 9
    )

    assert review.valid?
  end
end
