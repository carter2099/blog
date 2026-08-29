class ChangeReviewRatingScaleToTen < ActiveRecord::Migration[8.1]
  def up
    execute "UPDATE reviews SET rating = rating * 2.0"
  end

  def down
    execute "UPDATE reviews SET rating = rating / 2.0"
  end
end
