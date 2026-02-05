class HomeController < ApplicationController
  allow_unauthenticated_access only: %i[ index ]

  def index
    @post = Post.last
    @review = Review.order(created_at: :desc).first
  end
end
