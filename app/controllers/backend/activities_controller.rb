# coding: utf-8
# == License
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2013 David Joulin, Brice Texier
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
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

class Backend::ActivitiesController < Backend::BaseController
  manage_restfully

  unroll

  list do |t|
    t.column :name, url: true
    t.column :nature
    t.column :family
    # t.action :show, url: {format: :pdf}, image: :print
    t.action :edit
    t.action :destroy, if: :destroyable?
  end

  # List of productions for one activity
  list(:productions, conditions: {activity_id: 'params[:id]'.c}, order: {started_at: :desc}) do |t|
    t.column :name, url: true
    # t.column :product_nature, url: true
    t.column :state
    t.column :started_at
    t.column :stopped_at
  end

  # List of distribution for one activity
  list(:distributions, model: :activity_distributions, conditions: {activity_id: 'params[:id]'.c}) do |t|
    t.column :affectation_percentage, percentage: true
    t.column :main_activity, url: true
  end

end
