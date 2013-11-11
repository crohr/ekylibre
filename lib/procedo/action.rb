module Procedo

  # Type of action a task can do
  class Action
    TYPES = {
      # Localizations
      move_to: {product: :product, localizable: :product},
      move_in: {product: :product, localizable: :product},
      move_in_default_storage: {product: :product},
      move_in_given_default_storage: {product: :product, localizable: :product},
      # Productions
      production:  {product: :product, producible: :product},
      # Consumptions
      consumption: {product: :product, consumable: :product},
      # Deaths
      death: {product: :product},
      # Links
      attachment: {carrier: :product, carried: :product},
      detachment: {carrier: :product, carried: :product},
      # Memberships
      group_inclusion: {group: :product_group, member: :product},
      group_exclusion: {group: :product_group, member: :product},
      # Ownerships
      ownership_loss: {product: :product},
      owner_change:   {owner: :entity, product: :product},
      # Mergings
      merging:  {product: :product, merged: :product},
      # Divisions
      division: {product: :product, parted: :product},
      # Browsings
      browsing: {browser: :product, browsed: :product},
      # Measures
      simple_measure: {indicator: :indicator},
      measure: {indicator: :indicator, reporter: :product},
      assisted_measure: {indicator: :indicator, reporter: :product, tool: :product},
      # Deliveries
      outgoing_delivery: {product: :product},
      identified_outgoing_delivery: {product: :product, client: :entity},
      incoming_delivery: {product: :product},
      identified_incoming_delivery: {product: :product, supplier: :entity}
    }

    ACTORS = {
      indicator: "\\w+\\:\\w+(\\:\\w+)?"
    }

    attr_reader :type, :expression, :pattern

    def initialize(expression, type)
      unless TYPES[type]
        raise ArgumentError, "Action type #{type.inspect} is unknown. Expecting: #{TYPES.keys.to_sentence}."
      end
      @type = type
      @expression = expression
      stakeholders = definition.keys
      @expression.scan(/\{\w+\}/) do |expr|
        stakeholder = expr[1..-2].to_sym
        if definition[stakeholder]
          stakeholders.delete(stakeholder)
        else
          raise ArgumentError, "Unknown stakeholder for #{@type} action: #{stakeholder.inspect}"
        end
      end
      if stakeholders.any?
        raise InvalidExpression, "Expression #{@expression.inspect} doesn't give all stakeholders. Missing stakeholders: #{stakeholders.inspect}"
      end
      exp = "\\A" + @expression.gsub(/[[:space:]]+/, '\\s+').gsub(/\{[^\}]+\}/) do |actor|
        actor = actor[1..-2].to_sym
        e = ACTORS[definition[actor]] || "\\w+"
        # "\\[(?<#{actor}>#{e})\\]"
        "((?<#{actor}>#{e})|\\[(?<#{actor}>#{e})\\])"
      end + "\\z"
      # puts "#{@expression}: " + exp
      @pattern = Regexp.new(exp)
    end

    def match(expression)
      # puts [@pattern, expression].inspect
      return pattern.match(expression)
    end

    def definition
      TYPES[@type]
    end

  end


end