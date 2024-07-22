class CreateInventoryManagementSchema < ActiveRecord::Migration[7.1]
  def change
    create_table :categories do |t|
      t.string :name, null: false

      t.timestamps
    end

    add_index :categories, :id

    create_table :suppliers do |t|
      t.string :name, null: false

      t.timestamps
    end

    add_index :suppliers, :id

    create_table :warehouses do |t|
      t.string :name, null: false
      t.string :location, null: false

      t.timestamps
    end

    add_index :warehouses, :id

    create_table :items do |t|
      t.string :name, null: false
      t.references :category, foreign_key: true
      t.references :supplier, foreign_key: true
      t.references :warehouse, foreign_key: true

      t.timestamps
    end

    add_index :items, :id

    create_table :item_attributes do |t|
      t.references :item, foreign_key: true
      t.string :attribute_name, null: false
      t.string :attribute_value, null: false

      t.timestamps
    end

    add_index :item_attributes, :id

    create_table :items_denormalized do |t|
      t.string :name, null: false
      t.string :category_name
      t.string :supplier_name
      t.string :warehouse_name
      t.references :item, null: false, foreign_key: true
      t.references :category, null: false, foreign_key: true
      t.references :supplier, null: false, foreign_key: true
      t.references :warehouse, null: false, foreign_key: true

      t.timestamps
    end

    add_index :items_denormalized, :id
  end
end
