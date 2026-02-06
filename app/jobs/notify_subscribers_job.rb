class NotifySubscribersJob < ApplicationJob
  queue_as :default

  def perform(record)
    Subscriber.confirmed.find_each do |subscriber|
      case record
      when Post
        SubscriberMailer.with(subscriber: subscriber, post: record).new_post.deliver_later
      when Review
        SubscriberMailer.with(subscriber: subscriber, review: record).new_review.deliver_later
      end
    end
  end
end
