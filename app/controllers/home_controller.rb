class HomeController < ApplicationController
  allow_unauthenticated_access only: %i[ index ]

  def index
    @post = Post.last
  end
end
