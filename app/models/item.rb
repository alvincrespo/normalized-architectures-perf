class Item < ApplicationRecord
  belongs_to :category
  belongs_to :supplier
  belongs_to :warehouse
end
