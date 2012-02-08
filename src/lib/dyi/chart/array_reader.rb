# -*- encoding: UTF-8 -*-

# Copyright (c) 2009-2012 Sound-F Co., Ltd. All rights reserved.
#
# Author:: Mamoru Yuo
#
# This file is part of DYI.
#
# DYI is free software: you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# DYI is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with DYI.  If not, see <http://www.gnu.org/licenses/>.

module DYI
  module Chart

    # @since 0.0.0
    class ArrayReader
      # @since 0.0.0
      include Enumerable

      def [](i, j)
        @records[i].values[j]
      end

      # @return [Array] array of a struct
      # @since 1.0.0
      def records
        @records.clone
      end

      # @return [Integer] number of the records
      # @since 1.0.0
      def records_size
        @records.size
      end

      # @return [Integer] number of the values
      # @since 1.0.0
      def values_size
        @records.first.values.size rescue 0
      end

      def clear_data
        @records.clear
      end

      # @since 1.0.0
      def values_each(&block)
        @records.each do |record|
          yield record.values
        end
      end

      # @param [Integer] index index of series
      # @return [Array]
      # @since 1.0.0
      def series(index)
        @records.map do |record|
          record.values[index]
        end
      end

      # @since 1.0.0
      def has_field?(field_name)
        @schema.members.include?(RUBY_VERSION >= '1.9' ? field_name.to_sym : field_name.to_s)
      end

      # @since 1.0.0
      def each(&block)
        @records.each(&block)
      end

      def initialize
        @records = []
      end

      # Loads array-of-array and sets data.
      # @param [Array<Array>] array_of_array two dimensional array
      # @option options [Range] :row_range a range of rows
      # @option options [Range] :column_range a range of columns
      # @option options [Array<Symbol>] :schema array of field names
      # @option options [Array<Symbol>] :data_types array of field data types
      # @option options [Boolean] :transposed whether the array-of-array is
      #   transposed
      def read(array_of_array, options={})
        clear_data
        row_range = options[:row_range] || (0..-1)
        col_range = options[:column_range] || (0..-1)
        schema = options[:schema] || [:value]
        data_types = options[:data_types] || []
#        row_proc = options[:row_proc]
        @schema = record_schema(schema)
        array_of_array = transpose(array_of_array) if options[:transposed]

        array_of_array[row_range].each do |row|
          record_source = []
          values = []
          has_set_value = false
          row[col_range].each_with_index do |cell, i|
            cell = primitive_value(cell, data_types[i])
            if schema[i].nil? || schema[i].to_sym == :value
              unless has_set_value
                record_source << cell
                has_set_value = true
              end
              values << cell
            else
              record_source << cell
            end
          end
          record_source << values
          @records << @schema.new(*record_source)
        end
        self
      end

      # @return [Array] a array of a field's name (as Symbol)
      # @since 1.1.0
      def members
        @schema.members.map{|name| name.to_sym}
      end

      private

      def primitive_value(value, type=nil)
        value
      end

      # Transposes row and column of array-of-array.
      # @example
      #   transpose([[0,1,2],[3,4,5]]) => [[0,3],[1,4],[2,5]]
      # @param [Array] array_of_array array of array
      # @return [Array] transposed array
      # @since 1.0.0
      def transpose(array_of_array)
        transposed_array = []
        array_of_array.each_with_index do |row, i|
          row.each_with_index do |cell, j|
            transposed_array[j] ||= Array.new(i)
            transposed_array[j] << cell
          end
        end
        transposed_array
      end

      # @param [Array] schema of the record
      # @return [Class] subclass of Struct class
      # @since 1.0.0
      def record_schema(schema)
        struct_schema =
            schema.inject([]) do |result, name|
              if result.include?(name.to_sym)
                if name.to_sym == :value
                  next result
                else
                  raise ArgumentError, "schema option has a duplicate name: `#{name}'"
                end
              end
              if name.to_sym == :values
                raise ArgumentError, "schema option may not contain `:values'"
              end
              result << name.to_sym
            end
        struct_schema << :values
        Struct.new(*struct_schema)
      end

      # Makes the instance respond to xxx_values method.
      # @example
      #   data = ArrayReader.read([['Smith', 20, 3432], ['Thomas', 25, 9721]],
      #                           :schema => [:name, :age, :value])
      #   data.name_vlaues  # => ['Smith', 'Thomas']
      #   data.age_values   # => [20, 25]
      # @since 1.0.0
      def method_missing(name, *args)
        if args.size == 0 && name.to_s =~ /_values\z/ &&
            @schema.members.include?(RUBY_VERSION >= '1.9' ? $`.to_sym : $`)
          @records.map{|r| r.__send__($`)}
        else
          super
        end
      end

      class << self
        # Create a new instance of ArrayReader, loading array-of-array.
        # @param (see #read)
        # @option (see #read)
        # @return [ArrayReader] a new instance of ArrayReader
        def read(array_of_array, options={})
          new.read(array_of_array, options)
        end
      end
    end
  end
end
