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
# == Table: custom_fields
#
#  active          :boolean          default(TRUE), not null
#  column_name     :string           not null
#  created_at      :datetime         not null
#  creator_id      :integer
#  customized_type :string           not null
#  id              :integer          not null, primary key
#  lock_version    :integer          default(0), not null
#  maximal_length  :integer
#  maximal_value   :decimal(19, 4)
#  minimal_length  :integer
#  minimal_value   :decimal(19, 4)
#  name            :string           not null
#  nature          :string           not null
#  position        :integer
#  required        :boolean          default(FALSE), not null
#  updated_at      :datetime         not null
#  updater_id      :integer
#


class CustomField < Ekylibre::Record::Base
  attr_readonly :nature
  enumerize :nature, in: [:text, :decimal, :boolean, :date, :datetime, :choice], predicates: true
  enumerize :customized_type, in: (Ekylibre::Schema.model_names - [:AccountBalance, :AnalysisItem, :Affair, :Crumb, :CultivableZoneMembership, :CustomField, :CustomFieldChoice, :DocumentArchive, :FinancialAssetDepreciation, :Gap, :GapItem, :GuideAnalysis, :GuideAnalysisPoint, :IncomingDeliveryItem, :InterventionCast, :InventoryItem, :JournalEntryItem, :ListingNode, :ListingNodeItem, :ManureManagementPlan, :ManureManagementPlanZone, :Observation, :Operation, :OutgoingDeliveryItem, :Preference, :ProductBirth, :ProductConsumption, :ProductCreation, :ProductDeath, :ProductDivision, :ProductEnjoyment, :ProductionSupportMarker, :ProductJunction, :ProductJunctionWay, :ProductLink, :ProductLinkage, :ProductLocalization, :ProductMembership, :ProductMerging, :ProductMixing, :ProductNatureCategoryTaxation, :ProductNatureVariantReading, :ProductOwnership, :ProductPhase, :ProductQuadrupleMixing, :ProductQuintupleMixing, :ProductReading, :ProductReadingTask, :ProductTripleMixing, :PurchaseItem, :SaleItem, :User, :Version])
  has_many :choices, -> { order(:position) }, class_name: "CustomFieldChoice", dependent: :delete_all, inverse_of: :custom_field
  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_numericality_of :maximal_length, :minimal_length, allow_nil: true, only_integer: true
  validates_numericality_of :maximal_value, :minimal_value, allow_nil: true
  validates_inclusion_of :active, :required, in: [true, false]
  validates_presence_of :column_name, :customized_type, :name, :nature
  #]VALIDATORS]
  validates_length_of :nature, allow_nil: true, maximum: 20
  validates_inclusion_of :nature, in: self.nature.values
  validates_inclusion_of :customized_type, in: self.customized_type.values
  validates_uniqueness_of :column_name, scope: [:customized_type]
  validates_format_of :column_name, with: /\A(\_[a-z]+)+\z/
  validates_exclusion_of :column_name, in: ["_destroy"]

  accepts_nested_attributes_for :choices
  acts_as_list scope: 'customized_type = \'#{customized_type}\''

  # default_scope -> { order(:customized_type, :position) }
  scope :actives, -> { where(active: true).order(:position) }
  scope :of, lambda { |model| (customized_type.values.include?(model) ? where(active: true, customized_type: model).order(:position)  : none)}

  before_validation do
    self.column_name = ("_" + self.name.parameterize.gsub(/[^a-z]+/, '_').gsub(/(^\_+|\_+$)/, ''))[0..62]
    while self.others.where(column_name: self.column_name, customized_type: self.customized_type).any?
      self.column_name.succ!
    end
  end

  # Adds a new column in the given model
  after_save do
    unless self.column_exists?
      options = {}
      options.update(precision: 19, scale: 6) if self.column_type == :decimal
      self.class.connection.add_column(self.customized_table_name, self.column_name, self.column_type, options)
      if self.choice? and !self.index_exists?
        self.class.connection.add_index(self.customized_table_name, self.column_name, name: self.index_name)
      end
      reset_schema
    end
  end

  # Updates name of the column if necessary
  before_update do
    old = self.old_record
    if self.column_name != old.column_name and old.column_exists?
      self.class.connection.rename_column(self.customized_table_name, old.column_name, self.column_name)
      reset_schema
    end
  end

  # Destroy column and its data
  before_destroy do
    if self.column_exists?
      if self.index_exists?
        self.class.connection.remove_index(self.customized_table_name, self.column_name)
      end
      self.class.connection.remove_column(self.customized_table_name, self.column_name)
      reset_schema
    end
  end

  def reset_schema
    self.customized_model.reset_column_information
    self.customized_model.descendants.each(&:reset_column_information)
  end

  def choices_count
    self.choices.count
  end

  def sort_choices!
    self.choices.reorder(:name).to_a.each_with_index do |choice, index|
      choice.position = index + 1
      choice.save!
    end
  end

  # Returns the data type for the column
  def column_type
    return (self.choice? ? :string : self.nature).to_sym
  end

  # Check if column exists in DB
  def column_exists?
    self.class.connection.column_exists?(self.customized_table_name, self.column_name)
  end

  # Check if index exists in DB
  def index_exists?
    return false unless self.column_exists?
    self.class.connection.index_exists?(self.customized_table_name, self.column_name)
  end

  def index_name
    "index_#{self.customized_table_name}_on_cf_#{self.id}"
  end

  # Access to the customized model
  def customized_model
    return self.customized_type.constantize
  end

  # Returns to the customized table name
  def customized_table_name
    return self.customized_model.table_name
  end


end
