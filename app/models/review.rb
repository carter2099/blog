class Review < ApplicationRecord
  belongs_to :review_type

  validates :title, :rating, presence: true
  validates :rating, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 5 }
  validates :author, presence: true, if: :book?

  def book?
    review_type_id == ReviewType::BOOK
  end

  def formatted_rating
    "#{rating % 1 == 0.0 ? rating.to_i : rating}/5"
  end

  after_create_commit :notify_subscribers

  private
    def notify_subscribers
      NotifySubscribersJob.perform_later(self)
    end
end
