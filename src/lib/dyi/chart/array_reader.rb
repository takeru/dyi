# -*- encoding: UTF-8 -*-

# Copyright (c) 2009-2011 Sound-F Co., Ltd. All rights reserved.
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

module DYI #:nodoc:
  module Chart #:nodoc:

    class ArrayReader

      def [](i, j)
        @data[i][j]
      end

      def row_title(i)
        @row_titles[i]
      end

      def column_title(j)
        @col_titles[j]
      end

      def row_values(i)
        @data[i].dup
      end

      def column_values(j)
        @data.map{|r| r[j]}
      end

      def row_count
        @data.size
      end

      def column_count
        @data.first.size
      end

      def clear_data
        @data.clear
        @col_titles.clear
        @row_titles.clear
      end

      def values
        @data.dup
      end

      def column_titles
        @col_titles.dup
      end

      def row_titles
        @row_titles.dup
      end

      def initialize
        @data = []
        @col_titles = []
        @row_titles = []
      end

      def read(array_of_array, options={})
        clear_data
        data_types = options[:data_types] || []
        row_skip = (options[:row_skip].to_i rescue 0)
        col_skip = (options[:column_skip].to_i rescue 0)
        title_row = ((options[:title_row] ? options[:title_row].to_i : nil) rescue nil)
        title_col = ((options[:title_column] ? options[:title_column].to_i : nil) rescue nil)
        row_limit = ((options[:row_limit] ? options[:row_limit].to_i : nil) rescue nil)
        row_proc = options[:row_proc]
        array_of_array.each_with_index do |row, i|
          unless options[:transposed]
            if i == title_row
              @col_titles.replace(row[col_skip..-1].map{|v| primitive_title_value(v)})
            end
            next if i < row_skip
            break if row_limit && row_limit + row_skip <= i
            next if row_proc.respond_to?(:call) && !row_proc.call(*row[col_skip..-1])
            @row_titles << primitive_title_value(row[title_col]) if title_col
            vals = []
            row[col_skip..-1].each_with_index do |value, j|
              vals << primitive_value(value, data_types[j])
            end
            @data << vals
          else
            row_limit_number = row_limit ? row_limit + row_skip - 1 : -1
            if i == title_col
              @row_titles.replace(row[row_skip..row_limit_number].map{|v| primitive_title_value(v)})
            end
            next if i < col_skip
            vals = row[row_skip..row_limit_number]
            @data.replace(vals.map{|value| []}) if @data.empty?
            @col_titles << primitive_title_value(row[title_row]) if title_row
            vals.each_with_index do |value, j|
              @data[j] << primitive_value(value, data_types[i])
            end
          end
        end
        self
      end

      private

      def primitive_value(value, type=nil)
        value
      end

      def primitive_title_value(value, type=nil)
        primitive_value(value, type)
      end

      class << self
        def read(array_of_array, options={})
          new.read(array_of_array, options)
        end
      end
    end
  end
end
