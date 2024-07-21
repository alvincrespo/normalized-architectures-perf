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

starting = Process.clock_gettime(Process::CLOCK_MONOTONIC)
puts "Creating categories."
10.times do
  Category.create(name: Faker::Book.genre)
end
ending = Process.clock_gettime(Process::CLOCK_MONOTONIC)
elapsed = ending - starting
puts "Categories created. #{elapsed}"

starting = Process.clock_gettime(Process::CLOCK_MONOTONIC)
puts "Creating suppliers."
25.times do
  Supplier.create(name: Faker::Company.name)
end
ending = Process.clock_gettime(Process::CLOCK_MONOTONIC)
elapsed = ending - starting
puts "Suppliers created. #{elapsed}"

starting = Process.clock_gettime(Process::CLOCK_MONOTONIC)
puts "Creating warehouses."
1000.times do
  Warehouse.create(name: Faker::Company.name, location: Faker::Address.full_address)
end
ending = Process.clock_gettime(Process::CLOCK_MONOTONIC)
elapsed = ending - starting
puts "Warehouses created. #{elapsed}"

puts "Creating Items."
starting = Process.clock_gettime(Process::CLOCK_MONOTONIC)
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
ending = Process.clock_gettime(Process::CLOCK_MONOTONIC)
elapsed = ending - starting
puts "Items created. #{elapsed}"

puts "Batching inserting items."
starting = Process.clock_gettime(Process::CLOCK_MONOTONIC)
items.each_slice(1000) do |batch|
  Item.insert_all(batch)
end
ending = Process.clock_gettime(Process::CLOCK_MONOTONIC)
elapsed = ending - starting
puts "Batching completed. Items inserted. #{elapsed}"

# 1_000_000.times do
#   ItemAttribute.create(
#     attribute_name: Faker::Lorem.word,
#     attribute_value: Faker::Lorem.word,
#     item: Item.all.sample
#   )
# end

# Item.find_each do |item|
#   ItemsDenormalized.create(
#     item_id: item.id,
#     category_name: item.category.name,
#     supplier_name: item.supplier.name,
#     warehouse_name: item.warehouse.name,
#     attribute_name: item.item_attribute.attribute_name,
#     attribute_value: item.item_attribute.attribute_value
#   )
# end
