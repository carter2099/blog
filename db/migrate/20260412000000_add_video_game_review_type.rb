class AddVideoGameReviewType < ActiveRecord::Migration[8.1]
  def up
    execute <<~SQL
      INSERT INTO review_types (id, name, created_at, updated_at)
      VALUES (5, 'Video Game', datetime('now'), datetime('now'))
    SQL
  end

  def down
    execute <<~SQL
      DELETE FROM review_types WHERE id = 5
    SQL
  end
end
