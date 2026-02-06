class AllowNullPathOnReviews < ActiveRecord::Migration[8.1]
  def change
    change_column_null :reviews, :path, true
  end
end
