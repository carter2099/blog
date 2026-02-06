class Post < ApplicationRecord
  validates :title, :path, presence: true

  after_create_commit :notify_subscribers

  private
    def notify_subscribers
      NotifySubscribersJob.perform_later(self)
    end
end
