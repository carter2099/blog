class RemoveDateFromPosts < ActiveRecord::Migration[8.0]
  def change
    remove_column :posts, :date, :date
  end
end
