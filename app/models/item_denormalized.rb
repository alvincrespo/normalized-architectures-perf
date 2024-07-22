class ItemDenormalized < ApplicationRecord
  self.table_name = 'items_denormalized'

  belongs_to :item
  belongs_to :category
  belongs_to :supplier
  belongs_to :warehouse
end
