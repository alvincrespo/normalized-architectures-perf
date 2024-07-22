namespace :perf do


  desc "Run performance metrics for various queries"
  task run: :environment do

    def run_query(message, &block)
      puts "Running query #{message}."
      starting = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      yield if block_given?
      ending = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      elapsed = ending - starting
      puts "Query #{message.capitalize} completed. #{elapsed}"
    end


    run_query('normalized') do
      # SQL
      #
      # SELECT DISTINCT
      #   items.id,
      #   items.name,
      #   categories.name AS category_name,
      #   suppliers.name AS supplier_name,
      #   warehouses.name AS warehouse_name
      # FROM
      #   "items"
      #   INNER JOIN "categories" ON "categories"."id" = "items"."category_id"
      #   INNER JOIN "suppliers" ON "suppliers"."id" = "items"."supplier_id"
      #   INNER JOIN "warehouses" ON "warehouses"."id" = "items"."warehouse_id"
      #   LEFT OUTER JOIN "item_attributes" ON "item_attributes"."item_id" = "items"."id"
      # WHERE (items.supplier_id NOT IN(
      #     SELECT
      #       "suppliers"."id" FROM "suppliers"
      #     WHERE
      #       "suppliers"."name" = 'Feil Group'))
      #   AND(item_attributes.id NOT IN(
      #       SELECT
      #         "item_attributes"."id" FROM "item_attributes"
      #       WHERE
      #         "item_attributes"."attribute_name" IN('tenetur', 'sint')));
      #
      # Active Record Query
      #
      # Item Load (3171.9ms)  SELECT DISTINCT items.id, items.name, categories.name AS c
      # #
      Item
        .distinct
        .select('items.id, items.name, categories.name AS category_name, suppliers.name AS supplier_name, warehouses.name AS warehouse_name')
        .joins(:category, :supplier, :warehouse)
        .left_outer_joins(:item_attributes)
        .where("items.supplier_id NOT IN (#{Supplier.select('id').where(name: "Feil Group").to_sql})")
        .where("item_attributes.id NOT IN(#{ItemAttribute.select('id').where(attribute_name: ['tenetur', 'sint']).to_sql})")
        .to_a
    end

    run_query('denormalized') do
      # SQL
      #
      # SELECT DISTINCT
      #   items_denormalized.id AS id,
      #   items_denormalized.category_name AS category_name,
      #   items_denormalized.supplier_name AS supplier_name,
      #   items_denormalized.warehouse_name AS warehouse_name
      # FROM
      #   "items_denormalized"
      #   INNER JOIN "suppliers" ON "suppliers"."id" = "items_denormalized"."supplier_id"
      #   LEFT OUTER JOIN "item_attributes" ON "item_attributes"."item_id" = "items_denormalized"."item_id"
      # WHERE (items_denormalized.supplier_id NOT IN(
      #     SELECT
      #       "suppliers"."id" FROM "suppliers"
      #     WHERE
      #       "suppliers"."name" = 'Feil Group'))
      #   AND(item_attributes.id NOT IN(
      #       SELECT
      #         "item_attributes"."id" FROM "item_attributes"
      #       WHERE
      #         "item_attributes"."attribute_name" IN('tenetur', 'sint')));
      #
      # Active Record Query
      #
      # ItemDenormalized Load (2153.7ms)  SELECT DISTINCT items_denormalized.id as id, items_denormalized.category_name as
      #
      ItemDenormalized
      .distinct
      .select('items_denormalized.id as id, items_denormalized.category_name as category_name, items_denormalized.supplier_name as supplier_name, items_denormalized.warehouse_name as warehouse_name')
      .joins(:supplier)
      .joins('LEFT OUTER JOIN "item_attributes" ON "item_attributes"."item_id" = "items_denormalized"."item_id"')
      .where("items_denormalized.supplier_id NOT IN (#{Supplier.select('id').where(name: "Feil Group").to_sql})")
      .where("item_attributes.id NOT IN(#{ItemAttribute.select('id').where(attribute_name: ['tenetur', 'sint']).to_sql})")
      .to_a

      # RESULTS
      #
      # [1st RUN]
      # bundle exec rails perf:run
      #
      # Running query normalized.
      # Query Normalized completed. 3.730093999998644
      # Running query denormalized.
      # Query Denormalized completed. 2.504418000113219
      #
      # [2nd RUN]
      # bundle exec rails perf:run
      #
      # Running query normalized.
      # Query Normalized completed. 3.7837660000659525
      # Running query denormalized.
      # Query Denormalized completed. 2.4682920000050217
  end
  end
end
