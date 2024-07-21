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

ActiveRecord::Schema[7.1].define(version: 2024_07_21_110541) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "categories", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["id"], name: "index_categories_on_id"
  end

  create_table "item_attributes", force: :cascade do |t|
    t.bigint "item_id"
    t.string "attribute_name", null: false
    t.string "attribute_value", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["id"], name: "index_item_attributes_on_id"
    t.index ["item_id"], name: "index_item_attributes_on_item_id"
  end

  create_table "items", force: :cascade do |t|
    t.string "name", null: false
    t.bigint "category_id"
    t.bigint "supplier_id"
    t.bigint "warehouse_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["category_id"], name: "index_items_on_category_id"
    t.index ["id"], name: "index_items_on_id"
    t.index ["supplier_id"], name: "index_items_on_supplier_id"
    t.index ["warehouse_id"], name: "index_items_on_warehouse_id"
  end

  create_table "items_denormalized", force: :cascade do |t|
    t.string "name", null: false
    t.string "category_name"
    t.string "supplier_name"
    t.string "warehouse_name"
    t.string "attribute_name"
    t.string "attribute_value"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["id"], name: "index_items_denormalized_on_id"
  end

  create_table "suppliers", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["id"], name: "index_suppliers_on_id"
  end

  create_table "warehouses", force: :cascade do |t|
    t.string "name", null: false
    t.string "location", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["id"], name: "index_warehouses_on_id"
  end

  add_foreign_key "item_attributes", "items"
  add_foreign_key "items", "categories"
  add_foreign_key "items", "suppliers"
  add_foreign_key "items", "warehouses"
end
