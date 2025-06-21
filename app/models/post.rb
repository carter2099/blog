class Post < ApplicationRecord
  validates :title, :path, presence: true
end
