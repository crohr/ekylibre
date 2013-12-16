#
desc "Update models list file in lib/models.rb"
task :schema => :environment do
  print " - Schema: "

  models = CleanSupport.models_in_file

  symodels = models.collect{|x| x.name.underscore.to_sym}

  errors = 0
  schema_file = Rails.root.join("lib", "ekylibre", "schema", "reference.rb")

  schema_code  = "TABLES = {\n"
  schema_code << Ekylibre::Record::Base.connection.tables.sort.collect do |table|
    columns = Ekylibre::Record::Base.connection.columns(table).sort{|a,b| a.name <=> b.name }
    max = columns.map(&:name).map(&:size).max + 1
    model = table.classify.constantize rescue nil
    table_code  = "#{table}: {\n"
    table_code << columns.collect do |column|
      next if column.name =~ /\A\_/
      column_code  = (column.name.to_s + ":").ljust(max) + " Column.new(:" + (column.name.to_s + ",").ljust(max) + " " + (":" + column.type.to_s).rjust(10)
      if column.type == :decimal
        column_code << ", precision: #{column.precision}" if column.precision
        column_code << ", scale: #{column.scale}" if column.scale
      end
      if column.name =~ /\_id\z/
        reference_name = column.name.to_s[0..-4].to_sym
        unless val = Ekylibre::Schema.references(table, column)
          if column.name == "parent_id"
            val = model.name.underscore.to_sym
          elsif [:creator_id, :updater_id].include? column.name
            val = :user
          elsif columns.map(&:name).include?(reference_name.to_s + "_type")
            val = "#{reference_name}_type"
          elsif symodels.include? reference_name
            val = reference_name
          elsif model and reflection = model.reflections[reference_name]
            val = reflection.class_name.underscore.to_sym
          end
        end
        errors += 1 if val.nil?
        column_code << ", references: #{val.inspect}"
      end
      if column.type == :string and column.limit.to_i != 255
        column_code << ", limit: #{column.limit}"
      end
      if column.null.is_a? FalseClass
        column_code << ", null: false"
      end
      if column.default
        if column.type == :string
          column_code << ", default: #{column.default.inspect}"
        else
          column_code << ", default: #{column.default.to_s}"
        end
      end
      column_code << ").freeze"
      column_code
    end.join(",\n").dig
    table_code << "}.with_indifferent_access.freeze"
    table_code
  end.join(",\n").dig
  schema_code << "}.with_indifferent_access.freeze\n"

  File.open(schema_file, "wb") do |f|
    f.write("# Autogenerated from Ekylibre (`rake clean:schema` or `rake clean`)\n")
    f.write("module Ekylibre\n")
    f.write("  module Schema\n")

    f.write("    MODELS = [" + models.collect{|m| ":" + m.name.underscore}.join(", ") + "].freeze\n\n")

    f.write(schema_code.dig(2))
    f.write("\n")

    f.write("  end\n")
    f.write("end\n")
  end

  print "#{errors.to_s.rjust(3)} errors\n"
end