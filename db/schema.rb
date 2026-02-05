# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_02_05_220138) do
  create_table "posts", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "path"
    t.string "title"
    t.datetime "updated_at", null: false
  end

  create_table "review_types", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_review_types_on_name", unique: true
  end

  create_table "reviews", force: :cascade do |t|
    t.string "author"
    t.datetime "created_at", null: false
    t.string "path", null: false
    t.float "rating", null: false
    t.integer "review_type_id", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["rating"], name: "index_reviews_on_rating"
    t.index ["review_type_id"], name: "index_reviews_on_review_type_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email_address", null: false
    t.string "password_digest", null: false
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  add_foreign_key "reviews", "review_types"
  add_foreign_key "sessions", "users"
end
