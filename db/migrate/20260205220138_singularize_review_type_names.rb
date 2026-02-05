class SingularizeReviewTypeNames < ActiveRecord::Migration[8.1]
  def up
    execute <<~SQL
      UPDATE review_types SET name = 'Book' WHERE name = 'Books';
      UPDATE review_types SET name = 'Movie' WHERE name = 'Movies';
      UPDATE review_types SET name = 'Show' WHERE name = 'Shows';
      UPDATE review_types SET name = 'Product' WHERE name = 'Products';
    SQL
  end

  def down
    execute <<~SQL
      UPDATE review_types SET name = 'Books' WHERE name = 'Book';
      UPDATE review_types SET name = 'Movies' WHERE name = 'Movie';
      UPDATE review_types SET name = 'Shows' WHERE name = 'Show';
      UPDATE review_types SET name = 'Products' WHERE name = 'Product';
    SQL
  end
end
