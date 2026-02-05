class Review < ApplicationRecord
  REVIEW_TYPES = %w[Books Movies Shows Products].freeze

  validates :title, :review_type, :rating, :path, presence: true
  validates :review_type, inclusion: { in: REVIEW_TYPES }
  validates :rating, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 5 }
end
