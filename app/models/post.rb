class Post < ApplicationRecord
  validates :title, :date, :path, presence: true
end
