class AddMainImageToReviews < ActiveRecord::Migration[8.0]
  def change
    add_column :reviews, :main_image, :string
  end
end
