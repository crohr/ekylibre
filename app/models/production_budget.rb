# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2015 Brice Texier, David Joulin
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see http://www.gnu.org/licenses.
#
# == Table: production_budgets
#
#  amount             :decimal(19, 4)   default(0.0)
#  computation_method :string           not null
#  created_at         :datetime         not null
#  creator_id         :integer
#  currency           :string           not null
#  direction          :string           not null
#  id                 :integer          not null, primary key
#  lock_version       :integer          default(0), not null
#  production_id      :integer          not null
#  quantity           :decimal(19, 4)   default(0.0)
#  unit_amount        :decimal(19, 4)   default(0.0)
#  unit_currency      :string           not null
#  unit_indicator     :string
#  unit_population    :decimal(19, 4)
#  unit_unit          :string
#  updated_at         :datetime         not null
#  updater_id         :integer
#  variant_id         :integer
#

class ProductionBudget < Ekylibre::Record::Base
  # enumerize :currency, in: Nomen::Currencies.all, default: Preference[:currency]
  enumerize :direction, in: [:revenue, :expense], predicates: true
  enumerize :computation_method, in: [:per_production, :per_production_support, :per_working_unit], default: :per_working_unit, predicates: true
  enumerize :unit_indicator, in: Production.working_indicator.values
  enumerize :unit_unit, in: Nomen::Units.all.sort

  belongs_to :production
  belongs_to :variant, class_name: 'ProductNatureVariant'
  has_many :supports, through: :production, class_name: 'ProductionSupport'

  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_numericality_of :amount, :quantity, :unit_amount, :unit_population, allow_nil: true
  validates_presence_of :computation_method, :currency, :direction, :production, :unit_currency
  #]VALIDATORS]
  validates_presence_of :variant, :production

  delegate :supports, :supports_count, :working_indicator, :working_unit, to: :production
  delegate :name, to: :variant, prefix: true

  scope :revenues, -> { where(direction: :revenue) }
  scope :expenses, -> { where(direction: :expense) }

  before_validation do
    self.currency ||= self.unit_currency
  end

  validate do
    if self.currency and self.unit_currency
      errors.add(:currency, :invalid) if self.currency != self.unit_currency
    end
  end

  after_validation do
    self.amount = self.unit_amount * self.quantity
    if self.per_production_support?
      self.amount *= self.supports_count
    elsif self.per_working_unit?
      self.amount *= self.supports.map do |support|
        support.get(self.working_indicator).to_d(self.working_unit)
      end.sum
    end
  end

end
