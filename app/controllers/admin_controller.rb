class AdminController < ApplicationController
  def index
    @subscribers = Subscriber.order(created_at: :desc)
    @confirmed_count = Subscriber.confirmed.count
    @total_count = Subscriber.count
  end
end
