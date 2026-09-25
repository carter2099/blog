require "test_helper"

# Every request after the first carries the encrypted session cookie and the
# signed session_id cookie; both are decoded through ActiveSupport::JSON. A
# JSON library that breaks that decoding turns every page into a 500 for
# anyone holding a cookie, while cookie-less requests (and /up) still pass.
class SessionCookieTest < ActionDispatch::IntegrationTest
  test "visitor sent to sign in can load the sign-in page" do
    get admin_path
    assert_redirected_to new_session_path

    follow_redirect!
    assert_response :success
  end

  test "signed-in author keeps browsing with the session cookies" do
    post session_path, params: { email_address: users(:one).email_address, password: "password" }
    assert_redirected_to root_url

    get root_path
    assert_response :success

    get admin_path
    assert_response :success
  end
end
