class FixSingularizeReviewTypeNames < ActiveRecord::Migration[8.0]
  def up
    execute "UPDATE review_types SET name = 'Movie' WHERE name = 'Movies'"
    execute "UPDATE review_types SET name = 'Show' WHERE name = 'Shows'"
    execute "UPDATE review_types SET name = 'Product' WHERE name = 'Products'"
  end

  def down
    execute "UPDATE review_types SET name = 'Movies' WHERE name = 'Movie'"
    execute "UPDATE review_types SET name = 'Shows' WHERE name = 'Show'"
    execute "UPDATE review_types SET name = 'Products' WHERE name = 'Product'"
  end
end
