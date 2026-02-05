class ReviewType < ApplicationRecord
  BOOK = 1
  MOVIE = 2
  SHOW = 3
  PRODUCT = 4

  has_many :reviews

  validates :name, presence: true, uniqueness: true
end
