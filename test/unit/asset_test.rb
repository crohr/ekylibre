# = Informations
# 
# == License
# 
# Ekylibre - Simple ERP
# Copyright (C) 2009-2012 Brice Texier, Thibaud Merigon
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
# == Table: assets
#
#  account_id          :integer          not null
#  ceded               :boolean          
#  ceded_on            :date             
#  comment             :text             
#  company_id          :integer          not null
#  created_at          :datetime         not null
#  creator_id          :integer          
#  currency            :string(3)        
#  deprecated_amount   :decimal(19, 4)   not null
#  depreciable_amount  :decimal(19, 4)   not null
#  depreciation_method :string(255)      not null
#  description         :text             
#  id                  :integer          not null, primary key
#  journal_id          :integer          not null
#  lock_version        :integer          default(0), not null
#  name                :string(255)      not null
#  number              :string(255)      not null
#  purchase_amount     :decimal(19, 4)   not null
#  purchase_id         :integer          
#  purchase_line_id    :integer          
#  purchased_on        :date             not null
#  sale_id             :integer          
#  sale_line_id        :integer          
#  started_on          :date             not null
#  stopped_on          :date             not null
#  updated_at          :datetime         not null
#  updater_id          :integer          
#
require 'test_helper'

class AssetTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
