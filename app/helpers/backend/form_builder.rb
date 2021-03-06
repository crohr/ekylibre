# encoding: utf-8
# ##### BEGIN LICENSE BLOCK #####
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2009-2015 Brice Texier
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
# ##### END LICENSE BLOCK #####

# encoding: utf-8

class Backend::FormBuilder < SimpleForm::FormBuilder

  # Display a selector with "new" button
  def referenced_association(association, options = {}, &block)
    unless reflection = find_association_reflection(association)
      raise "Association #{association.inspect} not found"
    end
    if reflection.macro != :belongs_to
      raise ArgumentError, "Reflection #{reflection.name} must be a belongs_to"
    end

    if (options.delete(:as) || options.delete(:field)) == :hidden
      return self.association(association)
    end

    choices = options.delete(:source) || {}
    choices = {:scope => choices} if choices.is_a?(Symbol)
    choices[:action] ||= :unroll
    choices[:controller] ||= reflection.class_name.underscore.pluralize

    new_url = {}
    new_url[:controller] ||= choices[:controller]
    new_url[:action] ||= :new

    model = @object.class
    input_id = model.name.underscore + "_" + reflection.foreign_key.to_s

    html_options = options.delete(:input_html) || {}

    return input(reflection.foreign_key, options.merge(wrapper: (options[:wrapper] == :nested ? :nested_append : :append), reflection: reflection)) do
      self.input_field(reflection.foreign_key, html_options.deep_merge(as: :string, id: input_id, data: {selector: @template.url_for(choices), selector_new_item: @template.url_for(new_url), value_parameter_name: options[:value_parameter_name] || reflection.foreign_key}))
    end
  end

  # Display a selector with "new" button
  def referenced_association_field(association, options = {}, &block)
    reflection = find_association_reflection(association)
    raise "Association #{association.inspect} not found" unless reflection
    raise ArgumentError.new("Reflection #{reflection.name} must be a belongs_to") if reflection.macro != :belongs_to

    if (options.delete(:as) || options.delete(:field)) == :hidden
      return self.association(association)
    end

    choices = options.delete(:source) || {}
    choices = {:scope => choices} if choices.is_a?(Symbol)
    choices[:action] ||= :unroll
    choices[:controller] ||= reflection.class_name.underscore.pluralize

    new_url = {}
    new_url[:controller] ||= choices[:controller]
    new_url[:action] ||= :new

    model = @object.class
    input_id = model.name.underscore + "_" + reflection.foreign_key.to_s + "_id"

    html_options = options.delete(:input_html) || {}

    return self.input_field(reflection.foreign_key, html_options.deep_merge(as: :string, id: input_id, data: {selector: @template.url_for(choices), selector_new_item: @template.url_for(new_url)}))
  end

  # Adds nested association support
  def nested_association(association, *args, &block)
    options = args.extract_options!
    reflection = find_association_reflection(association)
    raise "Association #{association.inspect} not found" unless reflection
    ActiveSupport::Deprecation.warn "Nested association don't take code block anymore. Use partial '#{association.to_s.singularize}_fields' instead." if block_given?
    # raise ArgumentError.new("Reflection #{reflection.name} must be a has_many") if reflection.macro != :has_many
    item = association.to_s.singularize
    options[:locals] ||= {}
    html = self.simple_fields_for(association) do |nested|
      @template.render("#{item}_fields", options[:locals].merge(f: nested))
    end
    unless options[:new].is_a?(FalseClass)
      if reflection.macro == :has_many
        html << @template.content_tag(:div, @template.link_to_add_association("labels.add_#{item}".t, self, association, 'data-no-turbolink' => true, render_options: {locals: options[:locals]}, class: "nested-add add-#{item}"), :class => "links")
      end
    end
    return @template.content_tag(:div, html, :id => "#{association}-field")
  end

  # Adds custom fields
  def custom_fields(*args, &block)
    custom_fields = @object.custom_fields
    if custom_fields.any?
      return @template.content_tag(:div, :id => "custom-fields-field") do
        html = "".html_safe
        for custom_field in custom_fields
          options = {as: custom_field.nature.to_sym, required: custom_field.required?, label: custom_field.name}
          if custom_field.choice?
            options[:collection] = custom_field.choices.collect{|c| [c.name, c.value] }
          end
          html << self.input(custom_field.column_name, options)
        end
        html
      end
    end
    return nil
  end

  def indicator(indicator_attribute_name, unit_attribute_name, *args, &block)
    nil
  end

  # Updates default input method
  def input(attribute_name, options = {}, &block)
    if targets = options.delete(:show)
      options[:input_html] ||= {}
      options[:input_html]["data-show"] = clean_targets(targets)
    end
    if targets = options.delete(:hide)
      options[:input_html] ||= {}
      options[:input_html]["data-hide"] = clean_targets(targets)
    end
    return super(attribute_name, options, &block)
  end


  def picture(attribute_name = :picture, options = {}, &block)
    format = options.delete(:format) || :thumb
    return self.input(attribute_name, options) do
      html  = self.file_field(attribute_name)
      if @object.send(attribute_name).file?
        html << @template.content_tag(:div, @template.image_tag(@object.send(attribute_name).url(format)), :class => "preview picture")
      end
      html
    end
  end


  def items_list(attribute_name, options = {}, &block)
    prefix = @lookup_model_names.first +
             @lookup_model_names[1..-1].collect{|x| "[#{x}]"}.join +
             "[#{attribute_name}][]"
    options[:of] ||= :languages
    selection = []
    if options[:of].to_s =~ /\#/
      array = options[:of].to_s.split("#")
      selection = Nomen[array.first].property_natures[array.second].selection
    else
      selection = Nomen[options[:of]].selection
    end
    list = @object.send(attribute_name) || []
    return self.input(attribute_name, options) do
      @template.content_tag(:span, class: "control-group symbol-list") do
        selection.collect do |human_name, name|
          checked = list.include?(name.to_sym)
          @template.label_tag(nil, class: "nomenclature-item#{' checked' if checked}") do
            @template.check_box_tag(prefix, name, checked) +
              @template.content_tag(:span, human_name)
          end
        end.join.html_safe
      end
    end
  end


  def abilities_list(attribute_name = :abilities_list, options = {}, &block)
    prefix = @lookup_model_names.first +
             @lookup_model_names[1..-1].collect{|x| "[#{x}]"}.join +
             "[#{attribute_name}][]"
    return self.input(attribute_name, options) do
      data_lists = {}
      @template.content_tag(:span, class: "control-group abilities-list") do
        abilities_for_select = Nomen::Abilities.list.sort { |a, b| a.human_name <=> b.human_name }.map do |a|
          attrs = {value: a.name}
          if a.parameters
            a.parameters.each do |parameter|
              if parameter == :variety
                data_lists[parameter] ||= Nomen::Varieties.selection
              else
                raise "Unknown parameter type for an ability: #{parameter.inspect}"
              end
            end
            attrs[:data] = {ability_parameters: a.parameters.join(", ")}
          end
          @template.content_tag(:option, a.human_name, attrs)
        end.join.html_safe
        widget  = @template.content_tag(:span, class: "abilities") do
          if list = @object.send(attribute_name)
            list.collect do |a|
              ar = a.to_s.split(/[\(\,\s\)]+/).compact
              ability = Nomen::Abilities[ar.shift]
              @template.content_tag(:div, data: {ability: ability.name}, class: :ability) do
                html  = @template.label_tag ability.human_name
                html << @template.hidden_field_tag(prefix, a, class: "ability-value")
                ar.each_with_index do |p, index|
                  html << @template.select_tag(nil, @template.options_for_select(data_lists[ability.parameters[index]], p), data: {ability_parameter: index})
                end
                html << @template.link_to("#", data: {remove_closest: ".ability"}) do
                  @template.content_tag(:i)
                end
                html
              end
            end.join.html_safe
          end
        end
        attrs = {}
        widget << @template.select_tag("ability-creator", abilities_for_select, name: nil)
        widget << " ".html_safe
        widget << @template.link_to(:add.tl, "#ability-creator", data: {add_ability: prefix})
        data_lists.each do |key, selection|
          widget << @template.content_tag(:datalist, @template.options_for_select(selection), data: {ability_parameter_list: key})
        end
        widget
      end
    end
  end


  def shape(attribute_name = :shape, options = {})
    # raise @object.send(attribute_name)
    editor = {}
    if geom = @object.send(attribute_name)
      editor[:edit] = Charta::Geometry.new(geom).to_geojson
    else
      if sibling = @object.class.where("#{attribute_name} IS NOT NULL").first
        editor[:view] = {center: Charta::Geometry.new(sibling.send(attribute_name)).centroid }
      elsif zone = CultivableZone.first
        editor[:view] = {center: zone.shape_centroid}
      end
    end
    show = options.delete(:show) || @object.class.where("#{attribute_name} IS NOT NULL AND id != ?", @object.id || 0)
    union = Charta::Geometry.empty
    if show.any?
      show.collect do |obj|
        if shape = obj.send(attribute_name)
          union = union.merge(Charta::Geometry.new(shape))
        end
      end.compact
    else
      begin
        for obj in @object.class.where.not(id: @object.id || 0)
          union = union.merge Charta::Geometry.new(obj.send(:shape))
        end
      rescue
      end
    end
    unless union.empty?
      editor[:show] = union.to_geojson
    end
    return self.input(attribute_name, options.merge(input_html: {data: {map_editor: editor}}))
  end


  def shape_field(attribute_name = :shape, options = {})
    raise @object.send(attribute_name)
    geometry = Charta::Geometry.new(@object.send(attribute_name) || Charta::Geometry.empty)
    # return self.input(attribute_name, options.merge(input_html: {data: {spatial: geometry.to_geojson}}))
    return self.input_field(attribute_name, options.merge(input_html: {data: {map_editor: {edit: geometry.to_geojson}}}))
  end


  def geolocation(attribute_name = :geolocation, options = {})
    # raise @object.send(attribute_name)
    marker = {}
    if geom = @object.send(attribute_name)
      marker[:marker] = Charta::Geometry.new(geom).to_geojson["coordinates"].reverse
      marker[:view] = {center: marker[:marker]}
    else
      if sibling = @object.class.where("#{attribute_name} IS NOT NULL").first
        marker[:view] = {center: Charta::Geometry.new(sibling.send(attribute_name)).centroid }
      elsif zone = CultivableZone.first
        marker[:view] = {center: zone.shape_centroid}
      end
      marker[:marker] = marker[:view][:center] if marker[:view]
    end
    return self.input(attribute_name, options.merge(input_html: {data: {map_marker: marker}}))
  end



  def money(attribute_name, *args)
    options = args.extract_options!
    currency_attribute_name = args.shift || options[:currency_attribute] || :currency
    return self.input(attribute_name, options.merge(wrapper: :append)) do
      html  = self.input_field(attribute_name)
      html << self.input_field(currency_attribute_name, collection: Nomen::Currencies.items.values.collect{|c| [c.human_name, c.name.to_s]}.sort)
      html
    end
  end


  # Load a partial
  def subset(name, options = {}, &block)
    options[:id] ||= name
    if options[:depend_on]
      options['data-depend-on'] = options.delete(:depend_on)
    end
    if block_given?
      return @template.content_tag(:div, capture(&block), options)
    else
      return @template.content_tag(:div, @template.render(:partial => "#{name}_form", :locals => {:f => self, :object => @object}), options)
    end
  end


  def backend_fields_for(*args, &block)
    options = args.extract_options!
    options[:wrapper] = self.options[:wrapper] if options[:wrapper].nil?
    options[:defaults] ||= self.options[:defaults]

    if self.class < ActionView::Helpers::FormBuilder
      options[:builder] ||= self.class
    else
      options[:builder] ||= Backend::FormBuilder
    end
    fields_for(*(args << options), &block)
  end


  def product_form
    model = self.object.class
    while !@template.lookup_context.exists?("backend/#{model.name.tableize}/form", [], true) do
      model = model.superclass
      break if model == ActiveRecord::Base or model == Ekylibre::Record::Base
    end
    @template.render "backend/#{model.name.tableize}/form", f: self
  end


  # Build a frame for all product _forms
  def product_form_frame(options = {}, &block)
    html = ''.html_safe

    variant = @object.variant
    unless variant
      variant_id = @template.params[:variant_id]
      variant = ProductNatureVariant.where(id: variant_id.to_i).first if variant_id
    end
    if variant
      @object.nature ||= variant.nature
      whole_indicators = variant.whole_indicators
      # Add product type selector
      html << @template.field_set do
        fs  = self.input(:variant_id, value: variant.id, as: :hidden)
        # Add name
        fs << self.input(:name)
        # Add variant selector
        fs << self.variety(scope: variant)

        # error message for indicators
        if Rails.env.development?
          fs << @object.errors.inspect if @object.errors.any?
        end


        # Adds owner fields
        if @object.initializeable?
          fs << @template.render(partial: "backend/shared/initial_values_form", locals: {f: self})
        end

        # Add custom fields
        fs << self.custom_fields
        fs
      end


      # Add form body
      if block_given?
        html << @template.capture(&block)
      else
        html << @template.render(partial: "backend/shared/default_product_form", locals: {f: self})
      end

      # Add first indicators

      indicators = variant.variable_indicators.delete_if{|i| whole_indicators.include?(i) }
      if self.object.new_record? and indicators.any?

        for indicator in indicators
          @object.readings.build(indicator_name: indicator.name)
        end if @object.readings.empty?

        html << @template.field_set(:indicators) do
          fs = "".html_safe
          for reading in @object.readings
            indicator = reading.indicator
            # error message for indicators
            fs << reading.errors.inspect if reading.errors.any?
            fs << self.backend_fields_for(:readings, reading) do |indfi|
              fsi = "".html_safe
              fsi << indfi.input(:indicator_name, as: :hidden)
              fsi << indfi.input(:product_id, as: :hidden)
              fsi << indfi.input("#{indicator.datatype}_value_value", :wrapper => :append, :value => 0, :class => :inline, label: indicator.human_name) do
                m = "".html_safe
                if indicator.datatype == :measure
                  reading.measure_value_unit ||= indicator.unit
                  m << indfi.number_field("#{indicator.datatype}_value_value", label: indicator.human_name)
                  m << indfi.input_field("#{indicator.datatype}_value_unit", label: indicator.human_name, collection: Measure.siblings(indicator.unit).collect{|u| [Nomen::Units[u].human_name, u]})
                elsif indicator.datatype == :choice
                  m << indfi.input_field("#{indicator.datatype}_value", label: indicator.human_name, collection: indicator.selection(:choices))
                elsif [:boolean, :string, :decimal].include?(indicator.datatype)
                  m << indfi.input_field("#{indicator.datatype}_value", label: indicator.human_name, as: indicator.datatype)
                else
                  m << indfi.input_field("#{indicator.datatype}_value", label: indicator.human_name, as: :string)
                end
                if indfi.object.indicator_name_population?
                  m << @template.content_tag(:span, variant.unit_name, :class => "add-on")
                end
                m
              end
              fsi
            end
          end
          fs
        end
      end

    else
      clear_actions!
      variants = ProductNatureVariant.of_variety(@object.class.name.underscore)
      if variants.any?
        html << @template.subheading(:choose_a_type_of_product)
        html << @template.content_tag(:div, :class => "variant-list proposal-list") do
          buttons = "".html_safe
          for variant in ProductNatureVariant.of_variety(@object.class.name.underscore)
            buttons << @template.link_to(variant.name, {action: :new, variant_id: variant.id}, :class => "btn")
          end
          buttons
        end
      end

    end

    return html
  end


  def variety(options = {})
    scope = options[:scope]
    varieties         = Nomen::Varieties.selection(scope ? scope.variety : nil)
    @object.variety ||= (scope ? scope.variety : varieties.first ? varieties.first.last : nil)
    if options[:derivative_of] or (scope and scope.derivative_of)
      derivatives     = Nomen::Varieties.selection(scope ? scope.derivative_of : nil)
      @object.derivative_of ||= (scope ? scope.derivative_of : derivatives.first ? derivatives.first.last : nil)
      return self.input(:variety, wrapper: :append, :class => :inline) do
        field = ('<span class="add-on">' <<
                 ERB::Util.h(:x_of_y.tl(x: "{@@@@VARIETY@@@@}", y: "{@@@@DERIVATIVE@@@@}")) <<
                 '</span>')
        field.gsub!("{@@", '</span>')
        field.gsub!("@@}", '<span class="add-on">')
        field.gsub!('<span class="add-on"></span>', '')
        field.gsub!("@@VARIETY@@", self.input_field(:variety, as: :select, collection: varieties))
        field.gsub!("@@DERIVATIVE@@", self.input_field(:derivative_of, as: :select, collection: derivatives))
        field.html_safe
      end
    else
      return self.input(:variety, collection: varieties)
    end
  end


  def access_control_list(name = :rights)
    prefix = @lookup_model_names.first + @lookup_model_names[1..-1].collect{|x| "[#{x}]"}.join
    html = "".html_safe
    reference = @object.send(name) || {}
    for resource, accesses in Ekylibre::Access.list.sort{|a,b| Nomen::EnterpriseResources[a.first].human_name <=> Nomen::EnterpriseResources[b.first].human_name }
      resource_reference = reference[resource] || []
      html << @template.content_tag(:div, class: "control-group booleans") do
        @template.content_tag(:label, class: "control-label") do
          Nomen::EnterpriseResources[resource].human_name
        end +
          @template.content_tag(:div, class: "controls") do
          accesses.collect do |access, details|
            checked = resource_reference.include?(access)
            attributes = {class: "chk-access chk-access-#{access}", data: {access: "#{access}-#{resource}"}}
            if details["depend-on"]
              attributes[:data][:need_accesses] = details["depend-on"].join(" ")
            end
            attributes[:class] << " active" if checked
            @template.content_tag(:label, attributes) do
              @template.check_box_tag("#{prefix}[#{name}][#{resource}][]", access, checked) +
                ERB::Util.h(Nomen::EnterpriseResourceActions[access].human_name.strip)
            end
          end.join.html_safe
        end
      end
    end
    return html
  end

  def fields(partial = 'form')
    @template.content_tag(:div, @template.render(partial, f: self), class: "form-fields")
  end

  def actions
    return nil unless @actions.any?
    return @template.form_actions do
      html = "".html_safe
      for action in @actions
        if action[:type] == :block
          html << action[:content].html_safe
        else
          html << @template.send(action[:type], *action[:args])
        end
      end
      html
    end
  end

  def add(type = :block, *args, &block)
    @actions ||= []
    if type == :block
      @actions << {type: type, content: @template.capture(&block)}
    else
      type = {submit: :submit_tag, link: :link_to}[type] || type
      @actions << {type: type, args: args}
    end
    return true
  end

  def clear_actions!
    @actions = []
  end

  protected

  def clean_targets(targets)
    if targets.is_a?(String)
      return targets
    elsif targets.is_a?(Symbol)
      return "##{targets}"
    elsif targets.is_a?(Array)
      return targets.collect{|t| clean_targets(t)}.join(", ")
    else
      return targets.to_json
    end
    return targets
  end

end


# This hack permits to change default presentation of the DateTime input
class SimpleForm::Inputs::DateTimeInput

  def input_html_options
    value = object.send(attribute_name)
    # format = @options[:format] || :default
    # unless format.is_a?(Symbol)
    #   raise ArgumentError, "Option :format must be a Symbol referencing a translation 'date.formats.<format>'"
    # end
    # if localized_value = value
    #   localized_value = localized_value.l(format: format)
    # end
    # format = I18n.translate("#{input_type == :datetime ? :time : input_type}.formats.#{format}")
    # # format = I18n.translate("time.formats.#{format}")
    # Formize::DATE_FORMAT_TOKENS.each{|js, rb| format.gsub!(rb, js)}
    # Formize::TIME_FORMAT_TOKENS.each{|js, rb| format.gsub!(rb, js)}
    options = {
      # data: {
      #   format: format,
      #   human_value: localized_value
      # },
      lang: "i18n.iso2".t,
      value: value.blank? ? nil : value.l(format: "%Y-%m-%d#{' %H:%M' if input_type == :datetime}"),
      type: input_type,
      size: @options.delete(:size) || (input_type == :date  ? 10 : 16)
    }
    super.merge options
  end

  def label_target
    super
  end

  def input(wrapper_options = nil)
    @builder.text_field(attribute_name, input_html_options)
    # @builder.send("#{input_type}_field", attribute_name, input_html_options)
  end

end
