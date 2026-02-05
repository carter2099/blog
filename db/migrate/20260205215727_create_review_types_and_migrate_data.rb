class CreateReviewTypesAndMigrateData < ActiveRecord::Migration[8.1]
  def up
    create_table :review_types do |t|
      t.string :name, null: false
      t.timestamps
    end

    add_index :review_types, :name, unique: true

    execute <<~SQL
      INSERT INTO review_types (id, name, created_at, updated_at)
      VALUES (1, 'Books', datetime('now'), datetime('now')),
             (2, 'Movies', datetime('now'), datetime('now')),
             (3, 'Shows', datetime('now'), datetime('now')),
             (4, 'Products', datetime('now'), datetime('now'))
    SQL

    add_column :reviews, :review_type_id, :integer

    execute <<~SQL
      UPDATE reviews
      SET review_type_id = (
        SELECT id FROM review_types WHERE review_types.name = reviews.review_type
      )
    SQL

    change_column_null :reviews, :review_type_id, false
    add_foreign_key :reviews, :review_types
    add_index :reviews, :review_type_id

    remove_index :reviews, :review_type
    remove_column :reviews, :review_type
  end

  def down
    add_column :reviews, :review_type, :string

    execute <<~SQL
      UPDATE reviews
      SET review_type = (
        SELECT name FROM review_types WHERE review_types.id = reviews.review_type_id
      )
    SQL

    change_column_null :reviews, :review_type, false
    add_index :reviews, :review_type

    remove_foreign_key :reviews, :review_types
    remove_index :reviews, :review_type_id
    remove_column :reviews, :review_type_id

    drop_table :review_types
  end
end
