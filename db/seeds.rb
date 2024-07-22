# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end


require 'faker'

def create_records(message, &block)
  puts "Creating #{message}."
  starting = Process.clock_gettime(Process::CLOCK_MONOTONIC)
  yield if block_given?
  ending = Process.clock_gettime(Process::CLOCK_MONOTONIC)
  elapsed = ending - starting
  puts "#{message.capitalize} created. #{elapsed}"
end

puts 'Truncating database...'
ActiveRecord::Tasks::DatabaseTasks.truncate_all
puts 'Database truncated.'

create_records('categories') do
  10.times do
    Category.create(name: Faker::Book.genre)
  end
end

create_records('suppliers') do
  25.times do
    Supplier.create(name: Faker::Company.name)
  end
end

create_records('warehouses') do
  1000.times do
    Warehouse.create(name: Faker::Company.name, location: Faker::Address.full_address)
  end
end

create_records('items') do
  categories = Category.all.to_a
  suppliers = Supplier.all.to_a
  warehouses = Warehouse.all.to_a

  items = 100_000.times.map do
    {
      name: Faker::Commerce.product_name,
      category_id: categories.sample.id,
      supplier_id: suppliers.sample.id,
      warehouse_id: warehouses.sample.id
    }
  end

  items.each_slice(1000) do |batch|
    Item.insert_all(batch)
  end
end

create_records('item attributes') do
  items = Item.all

  item_attributes = 1_000_000.times.map do
    {
      attribute_name: Faker::Lorem.word,
      attribute_value: Faker::Lorem.word,
      item_id: items.sample.id
    }
  end

  item_attributes.each_slice(1000) do |batch|
    ItemAttribute.insert_all(batch)
  end
end

create_records('denormalized items') do
  items_with_associations = Item.includes(:category, :supplier, :warehouse)

  denormalized_items_attributes = []

  items_with_associations.find_each(batch_size: 1000) do |item|
    denormalized_items_attributes << {
      name: item.name,
      item_id: item.id,
      category_name: item.category.name,
      category_id: item.category.id,
      supplier_name: item.supplier.name,
      supplier_id: item.supplier.id,
      warehouse_name: item.warehouse.name,
      warehouse_id: item.warehouse.id,
      created_at: DateTime.now,
      updated_at: DateTime.now
    }
  end

  denormalized_items_attributes.each_slice(1000) do |batch|
    ItemDenormalized.insert_all(batch)
  end
end
