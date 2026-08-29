require "test_helper"

class ReviewsControllerTest < ActionDispatch::IntegrationTest
  test "pagination keeps filters and sorting across pages" do
    timestamp = Time.zone.parse("2026-01-01 12:00:00")
    matching_reviews = 12.times.map do |index|
      {
        title: format("Match %02d", index),
        review_type_id: review_types(:movie).id,
        rating: index / 2,
        author: nil,
        created_at: timestamp,
        updated_at: timestamp
      }
    end
    Review.insert_all!(matching_reviews + [
      {
        title: "Match Book",
        review_type_id: review_types(:book).id,
        rating: 0,
        author: "Author",
        created_at: timestamp,
        updated_at: timestamp
      },
      {
        title: "Different Movie",
        review_type_id: review_types(:movie).id,
        rating: 0,
        author: nil,
        created_at: timestamp,
        updated_at: timestamp
      }
    ])

    get reviews_path, params: { review_type: "Movie", q: "Match", sort: "rating_asc" }

    assert_response :success
    assert_equal [
      "Match 01", "Match 00", "Match 03", "Match 02", "Match 05",
      "Match 04", "Match 07", "Match 06", "Match 09", "Match 08"
    ], css_select(".review-card > a").map(&:text)
    assert_select ".review-card", count: 10
    assert_select ".pagination", text: /Page 1 of 2/

    next_link = css_select(".pagination a[rel='next']").first
    assert_equal({
      "review_type" => "Movie",
      "q" => "Match",
      "sort" => "rating_asc",
      "page" => "2"
    }, Rack::Utils.parse_query(URI.parse(next_link["href"]).query))

    get next_link["href"]

    assert_response :success
    assert_equal [ "Match 11", "Match 10" ], css_select(".review-card > a").map(&:text)
    assert_select ".pagination", text: /Page 2 of 2/

    previous_link = css_select(".pagination a[rel='prev']").first
    assert_equal({
      "review_type" => "Movie",
      "q" => "Match",
      "sort" => "rating_asc",
      "page" => "1"
    }, Rack::Utils.parse_query(URI.parse(previous_link["href"]).query))
  end
end
