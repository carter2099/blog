class Post < ApplicationRecord
  validates :title, presence: true
  has_rich_text :body
end
