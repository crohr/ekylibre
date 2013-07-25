# = Informations
#
# == License
#
# Ekylibre - Simple ERP
# Copyright (C) 2009-2013 Brice Texier, Thibaud Merigon
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see http://www.gnu.org/licenses.
#
# == Table: outgoing_delivery_items
#
#  created_at   :datetime         not null
#  creator_id   :integer
#  delivery_id  :integer          not null
#  id           :integer          not null, primary key
#  lock_version :integer          default(0), not null
#  move_id      :integer
#  product_id   :integer          not null
#  quantity     :decimal(19, 4)   default(1.0), not null
#  sale_item_id :integer
#  updated_at   :datetime         not null
#  updater_id   :integer
#


class OutgoingDeliveryItem < Ekylibre::Record::Base
  attr_accessible :sale_item_id, :product_id, :price_id, :unit
  attr_readonly :sale_item_id, :product_id, :price_id, :unit
  belongs_to :delivery, :class_name => "OutgoingDelivery", :inverse_of => :items
  # belongs_to :price, :class_name => "ProductPrice"
  belongs_to :product
  belongs_to :sale_item
  # belongs_to :move, :class_name => "ProductMove"
  enumerize :unit, :in => Nomen::Units.all
  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_numericality_of :quantity, :allow_nil => true
  validates_presence_of :delivery, :product, :quantity
  #]VALIDATORS]
  validates_presence_of :product, :unit

  acts_as_stockable :quantity => '-self.quantity', :origin => :delivery
  sums :delivery, :items, :pretax_amount, :amount, "(item.product.weight||0)*item.quantity" => :weight

  before_validation do
    if self.sale_item
      self.product_id  = self.sale_item.product_id
      self.price_id    = self.sale_item.price.id
      self.unit     = self.sale_item.unit
    end
    self.pretax_amount = self.sale_item.price.pretax_amount*self.quantity
    self.amount = self.sale_item.price.amount*self.quantity
    true
  end

  validate(:on => :create) do
    if self.product
      maximum = self.undelivered_quantity
      errors.add(:quantity, :greater_than_undelivered_quantity, :maximum => maximum, :unit => self.product.unit.name, :product => self.product_name) if (self.quantity > maximum)
    end
    true
  end

  validate(:on => :update) do
    old_self = self.class.find(self.id)
    maximum = self.undelivered_quantity + old_self.quantity
    errors.add(:quantity, :greater_than_undelivered_quantity, :maximum => maximum, :unit => self.product.unit.name, :product => self.product_name) if (self.quantity > maximum)
  end

  def undelivered_quantity
    self.sale_item.undelivered_quantity
  end

  def product_name
    self.product.name
  end

end