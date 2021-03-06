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
# == Table: entities
#
#  active                    :boolean          default(TRUE), not null
#  activity_code             :string
#  authorized_payments_count :integer
#  born_at                   :datetime
#  client                    :boolean          default(FALSE), not null
#  client_account_id         :integer
#  country                   :string
#  created_at                :datetime         not null
#  creator_id                :integer
#  currency                  :string           not null
#  dead_at                   :datetime
#  deliveries_conditions     :string
#  description               :text
#  first_met_at              :datetime
#  first_name                :string
#  full_name                 :string           not null
#  id                        :integer          not null, primary key
#  language                  :string           not null
#  last_name                 :string           not null
#  lock_version              :integer          default(0), not null
#  locked                    :boolean          default(FALSE), not null
#  meeting_origin            :string
#  nature                    :string           not null
#  number                    :string
#  of_company                :boolean          default(FALSE), not null
#  picture_content_type      :string
#  picture_file_name         :string
#  picture_file_size         :integer
#  picture_updated_at        :datetime
#  proposer_id               :integer
#  prospect                  :boolean          default(FALSE), not null
#  reminder_submissive       :boolean          default(FALSE), not null
#  responsible_id            :integer
#  siren                     :string
#  supplier                  :boolean          default(FALSE), not null
#  supplier_account_id       :integer
#  transporter               :boolean          default(FALSE), not null
#  type                      :string
#  updated_at                :datetime         not null
#  updater_id                :integer
#  vat_number                :string
#  vat_subjected             :boolean          default(TRUE), not null
#
class Person < Entity
  enumerize :nature, in: Nomen::EntityNatures.all(:person), default: Nomen::EntityNatures.default(:person), predicates: {prefix: true}

  has_one :worker
  has_one :user
  has_one :team, through: :user
  scope :users, -> { where(id: User.all) }

  scope :employees, -> { joins(:direct_links).merge(EntityLink.of_nature(:work)) }

  scope :employees_of, lambda { |boss|
    joins(:direct_links).merge(EntityLink.of_nature(:work).where(entity_2_id: (boss.respond_to?(:id) ? boss.id : boss)))
  }

end
