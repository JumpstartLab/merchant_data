require 'csv'

module Exporter
  DEFAULT_EXPORT_TABLES = [ Invoice, InvoiceItem, Item, Merchant, Transaction, User ]
  DESTINATION_FOLDER = "tmp/"

  def self.included(klass)
    klass.extend ClassLevelMethods
  end

  def self.export_tables_to_csv(tables = DEFAULT_EXPORT_TABLES)
    tables.each &:export_table_to_csv
  end

  def data
    self.class.column_names.map { |column| send(column) }
  end

  module ClassLevelMethods
    def export_table_to_csv
      CSV.open(filename_for_class, "w") do |output_file|
        output_file << column_names
        data.each{ |row| output_file << row }
      end
    end

    def filename_for_class
      [DESTINATION_FOLDER, to_s.pluralize.underscore, '.csv'].join
    end

    def data
      all.map(&:data)
    end
  end
end

class ActiveRecord::Base
  include Exporter
end