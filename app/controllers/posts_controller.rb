class PostsController < ApplicationController
  allow_unauthenticated_access only: %i[ index show ]

  def index
  end

  def show
  end
end
