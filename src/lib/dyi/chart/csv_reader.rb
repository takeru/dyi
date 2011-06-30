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

require 'csv'
require 'date'
require 'bigdecimal'
require 'nkf'

module DYI #:nodoc:
  module Chart #:nodoc:

    class CsvReader < ArrayReader
      def read(path, options={})
        options = options.dup
        @date_format = options.delete(:date_format)
        @datetime_format = options.delete(:datetime_format)
        nkf_options =
          case (options[:encode] || :utf8).to_sym
            when :utf8 then nil
            when :sjis then '-w -S -m0 -x --cp932'
            when :euc then '-w -E -m0 -x --cp932'
            when :jis then '-w -J -m0 -x'
            when :utf16 then '-w -W16 -m0 -x'
            else raise ArgumentError,"Unknown encode: `#{@encode}'"
          end
        parsed_array = 
          if RUBY_VERSION >= '1.9'
            CSV.parse(nkf_options ? NKF.nkf(nkf_options, IO.read(path)) : IO.read(path), :col_sep => options[:col_sep] || ',', :row_sep => options[:row_sep] || :auto)
          else
            CSV.parse(nkf_options ? NKF.nkf(nkf_options, IO.read(path)) : IO.read(path), options[:col_sep], options[:row_sep])
          end
        super(parsed_array, options)
      end

      private

      def primitive_value(value, type)
        if type.is_a?(Symbol) || type.is_a?(String)
          case type.to_sym
          when :string
            value || ''
          when :number, :decimal
            value ? BigDecimal.new(value) : nil
          when :float
            value ? value.to_f : nil
          when :integer
            value ? value.to_i : nil
          when :date
            return nil if value.nil?
            @date_format ? Date.strptime(value, @date_format) : Date.parse(value)
          when :datetime
            return nil if value.nil?
            @datetime_format ? DateTime.strptime(value, @datetime_format) : DateTime.parse(value)
          when :boolean
            value ? true : value
          else
            value ? value.to_f : nil
          end
        else
          value ? value.to_f : nil
        end
      end

      def primitive_title_value(value, type=nil)
        value
      end

      class << self
        def read(path, options={})
          new.read(path, options)
        end
      end
    end
  end
end
