class Review < ApplicationRecord
  belongs_to :review_type

  validates :title, :rating, :path, presence: true
  validates :rating, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 5 }
  validates :author, presence: true, if: :book?

  def book?
    review_type_id == ReviewType::BOOK
  end
end
