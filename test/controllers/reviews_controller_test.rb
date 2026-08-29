require "test_helper"

class ReviewsControllerTest < ActionDispatch::IntegrationTest
  test "pagination keeps filters and sorting across pages" do
    timestamp = Time.zone.parse("2026-01-01 12:00:00")
    matching_reviews = 22.times.map do |index|
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

    filter_params = { review_type: "Movie", q: "Match", sort: "rating_asc" }
    expected_query = filter_params.transform_keys(&:to_s)
    query_for = ->(link) { Rack::Utils.parse_query(URI.parse(link["href"]).query) }

    get reviews_path, params: filter_params

    assert_response :success
    assert_equal [
      "Match 01", "Match 00", "Match 03", "Match 02", "Match 05",
      "Match 04", "Match 07", "Match 06", "Match 09", "Match 08"
    ], css_select(".review-card > a").map(&:text)
    assert_select ".review-card", count: 10
    assert_select ".pagination", text: /Page 1 of 3/

    next_link = css_select(".pagination a[rel='next']").first
    last_link = css_select(".pagination a[rel='last']").first
    assert_equal expected_query.merge("page" => "2"), query_for.call(next_link)
    assert_equal expected_query.merge("page" => "3"), query_for.call(last_link)

    get next_link["href"]

    assert_response :success
    assert_equal [
      "Match 11", "Match 10", "Match 13", "Match 12", "Match 15",
      "Match 14", "Match 17", "Match 16", "Match 19", "Match 18"
    ], css_select(".review-card > a").map(&:text)
    assert_select ".pagination", text: /Page 2 of 3/

    first_link = css_select(".pagination a[rel='first']").first
    previous_link = css_select(".pagination a[rel='prev']").first
    next_link = css_select(".pagination a[rel='next']").first
    last_link = css_select(".pagination a[rel='last']").first
    assert_equal expected_query.merge("page" => "1"), query_for.call(first_link)
    assert_equal expected_query.merge("page" => "1"), query_for.call(previous_link)
    assert_equal expected_query.merge("page" => "3"), query_for.call(next_link)
    assert_equal expected_query.merge("page" => "3"), query_for.call(last_link)

    get last_link["href"]

    assert_response :success
    assert_equal [ "Match 21", "Match 20" ], css_select(".review-card > a").map(&:text)
    assert_select ".pagination", text: /Page 3 of 3/

    first_link = css_select(".pagination a[rel='first']").first
    assert_equal expected_query.merge("page" => "1"), query_for.call(first_link)

    get first_link["href"]

    assert_response :success
    assert_select ".pagination", text: /Page 1 of 3/
  end
end
