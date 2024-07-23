require 'active_support/notifications'

namespace :perf do

  desc "Run performance metrics for various queries"
  task run: :environment do
    TAG = 'PERF_METRIC'

    ActiveSupport::Notifications.subscribe('sql.active_record') do |name, start, finish, id, payload|
      if payload[:sql].include?(TAG)
        elapsed_time = finish - start
        puts("Elapsed Query Time: #{elapsed_time.round(2)} seconds")
      end
    end

    normalized_results = []
    denormalized_results = []

    def run_query(message, arr, &block)
      puts "Running query #{message}."
      starting = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      yield if block_given?
      ending = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      elapsed = ending - starting
      arr << elapsed
      puts "Query #{message.capitalize} completed. #{elapsed} \n\n"
    end

    #
    # Background / Story
    #
    # I want a report of all items that are not supplied by X
    # and that do not have the attribute names Y and Z.
    #
    # Ex.
    #
    # I request a report of all items except thsoe from supplier
    # sint and that do not have the following attributes: tenetur, sint.
    #

    10.times.each do
      #
      # Lets run a query to retrieve these items using the normalized
      # structure of the items table.
      #
      # We are going to do multiple joins (which are not that source of the issue in this example)
      # and are going to use NOT IN for the item_attributes check.
      #
      run_query('normalized', normalized_results) do
        # SQL
        #
        # SELECT
        #     DISTINCT items.id,
        #     items.name,
        #     categories.name AS category_name,
        #     suppliers.name AS supplier_name,
        #     warehouses.name AS warehouse_name
        # FROM
        #     "items"
        #     INNER JOIN "categories" ON "categories"."id" = "items"."category_id"
        #     INNER JOIN "suppliers" ON "suppliers"."id" = "items"."supplier_id"
        #     INNER JOIN "warehouses" ON "warehouses"."id" = "items"."warehouse_id"
        #     LEFT OUTER JOIN "item_attributes" ON "item_attributes"."item_id" = "items"."id"
        # WHERE
        #     (
        #         items.supplier_id NOT IN (
        #             SELECT
        #                 "suppliers"."id"
        #             FROM
        #                 "suppliers"
        #             WHERE
        #                 "suppliers"."name" = 'Feil Group'
        #         )
        #     )
        #     AND (
        #         items.id NOT IN(
        #             SELECT
        #                 "item_attributes"."item_id"
        #             FROM
        #                 "item_attributes"
        #             WHERE
        #                 "item_attributes"."attribute_name" IN ('tenetur', 'sint')
        #         )
        #     )
        #
        # Active Record Query
        #
        # Item Load (3171.9ms)  SELECT DISTINCT items.id, items.name, categories.name AS c
        #
        #
        excluded_suppliers =
          Supplier
            .select('id')
            .where(name: "Feil Group")
            .to_sql

        excluded_attributes =
          ItemAttribute
            .select(:item_id)
            .where(attribute_name: ['tenetur', 'sint'])
            .to_sql

        Item
          .distinct
          .select('/* PERF_METRIC */ items.id, items.name, categories.name AS category_name, suppliers.name AS supplier_name, warehouses.name AS warehouse_name')
          .joins(:category, :supplier, :warehouse)
          .left_outer_joins(:item_attributes)
          .where("items.supplier_id NOT IN (#{excluded_suppliers})")
          .where("items.id NOT IN(#{excluded_attributes})")
          .to_a
      end

      #
      # Now, lets run a query to retrieve these items using the denormalized
      # structure from the items_denormalized table.
      #
      #
      # We are going to do one join and are going to use
      # NOT EXIST which improves our query performance.
      #
      run_query('denormalized', denormalized_results) do
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
        # WHERE
        #   items_denormalized.supplier_id NOT IN(
        #     SELECT
        #       "suppliers"."id" FROM "suppliers"
        #     WHERE
        #       "suppliers"."name" = 'Feil Group')
        #   AND NOT EXISTS (
        #     SELECT
        #       1
        #     FROM
        #       "item_attributes" ia
        #     WHERE
        #       ia.item_id = items_denormalized.item_id
        #       AND ia.attribute_name IN('tenetur', 'sint'));
        #
        # Active Record Query
        #
        # ItemDenormalized Load (2153.7ms)  SELECT DISTINCT items_denormalized.id as id, items_denormalized.category_name as
        #
        #
        excluded_suppliers =
          Supplier
            .select('id')
            .where(name: "Feil Group")
            .to_sql

        excluded_attributes =
          ItemAttribute
            .select('1')
            .from('item_attributes as ia')
            .where('ia.item_id = items_denormalized.item_id')
            .where('ia.attribute_name IN (?)', ['tenetur', 'sint'])
            .to_sql

        ItemDenormalized
          .distinct
          .select('/* PERF_METRIC */ items_denormalized.id as id, items_denormalized.category_name as category_name, items_denormalized.supplier_name as supplier_name, items_denormalized.warehouse_name as warehouse_name')
          .joins(:supplier)
          .joins('LEFT OUTER JOIN "item_attributes" ON "item_attributes"."item_id" = "items_denormalized"."item_id"')
          .where("items_denormalized.supplier_id NOT IN (#{excluded_suppliers})")
          .where("NOT EXISTS (#{excluded_attributes})")
          .to_a
      end
    end

    average_normalized = normalized_results.sum / normalized_results.size.to_f
    puts "Average normalized results: #{average_normalized}"

    average_denormalized = denormalized_results.sum / denormalized_results.size.to_f
    puts "Average denormalized results: #{average_denormalized}"

    performance_gain = ((average_normalized - average_denormalized) / average_normalized) * 100
    puts "Performance Gain: #{performance_gain}%"


    # RESULTS
    # bundle exec rails perf:run
    # Running query normalized.
    # Elapsed Query Time: 1.84 seconds
    # Query Normalized completed. 2.4665169999934733

    # Running query denormalized.
    # Elapsed Query Time: 0.27 seconds
    # Query Denormalized completed. 0.5184240001253784

    # Running query normalized.
    # Elapsed Query Time: 1.81 seconds
    # Query Normalized completed. 2.0653859998565167

    # Running query denormalized.
    # Elapsed Query Time: 0.31 seconds
    # Query Denormalized completed. 0.5063189999200404

    # Running query normalized.
    # Elapsed Query Time: 1.9 seconds
    # Query Normalized completed. 2.1012680002022535

    # Running query denormalized.
    # Elapsed Query Time: 0.28 seconds
    # Query Denormalized completed. 0.47876300010830164

    # Running query normalized.
    # Elapsed Query Time: 2.06 seconds
    # Query Normalized completed. 2.2599939999636263

    # Running query denormalized.
    # Elapsed Query Time: 0.28 seconds
    # Query Denormalized completed. 0.47612399980425835

    # Running query normalized.
    # Elapsed Query Time: 1.82 seconds
    # Query Normalized completed. 2.025857000146061

    # Running query denormalized.
    # Elapsed Query Time: 0.3 seconds
    # Query Denormalized completed. 0.4960139999166131

    # Running query normalized.
    # Elapsed Query Time: 1.82 seconds
    # Query Normalized completed. 2.026073999935761

    # Running query denormalized.
    # Elapsed Query Time: 0.28 seconds
    # Query Denormalized completed. 0.47480099997483194

    # Running query normalized.
    # Elapsed Query Time: 1.82 seconds
    # Query Normalized completed. 2.0250770000275224

    # Running query denormalized.
    # Elapsed Query Time: 0.28 seconds
    # Query Denormalized completed. 0.4754550000652671

    # Running query normalized.
    # Elapsed Query Time: 1.82 seconds
    # Query Normalized completed. 2.0233620000071824

    # Running query denormalized.
    # Elapsed Query Time: 0.28 seconds
    # Query Denormalized completed. 0.4784549998585135

    # Running query normalized.
    # Elapsed Query Time: 1.83 seconds
    # Query Normalized completed. 2.0368000001180917

    # Running query denormalized.
    # Elapsed Query Time: 0.28 seconds
    # Query Denormalized completed. 0.4728459999896586

    # Running query normalized.
    # Elapsed Query Time: 1.81 seconds
    # Query Normalized completed. 2.0122070000506938

    # Running query denormalized.
    # Elapsed Query Time: 0.28 seconds
    # Query Denormalized completed. 0.4744090000167489

    # Average normalized results: 2.1042542000301183
    # Average normalized results: 0.4851609999779612
    # Performance Gain: 76.94380270354138%

    #
    # TODO: Showcase the performance implications of joining on joins
    # with the nested join having millions of records.
    #
  end
end
