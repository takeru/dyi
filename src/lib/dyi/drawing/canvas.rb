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
  module Drawing #:nodoc:

    class Canvas
      extend AttributeCreator
      IMPLEMENT_ATTRIBUTES = [:view_box, :preserve_aspect_ratio]
      attr_length :width, :height
      attr_reader *IMPLEMENT_ATTRIBUTES
      attr_reader :child_elements

      def initialize(width, height, real_width = nil, real_height = nil, preserve_aspect_ratio='none')
        self.width = width
        self.height = height
        @view_box = "0 0 #{width} #{height}"
        @preserve_aspect_ratio = preserve_aspect_ratio
        @child_elements = []
        self.real_width = real_width
        self.real_height = real_height
      end

      def real_width
        @real_width || width
      end

      def real_width=(width)
        @real_width = Length.new_or_nil(width)
      end

      def real_height
        @real_height || height
      end

      def real_height=(height)
        @real_height = Length.new_or_nil(height)
      end

      def root_node?
        true
      end

      def write_as(formatter, io=$>)
        formatter.write_canvas(self, io)
      end

      def save(file_name, format=nil, options={})
        get_formatter(format).save(file_name, options)
      end

      def puts_in_io(format=nil, io=$>)
        get_formatter(format).puts(io)
      end

      def string(format=nil)
        get_formatter(format).string
      end

      def attributes #:nodoc:
        attrs = {:width => real_width, :height => real_height}
        IMPLEMENT_ATTRIBUTES.inject(attrs) do |hash, attribute|
          variable_name = '@' + attribute.to_s.split(/(?=[A-Z])/).map{|str| str.downcase}.join('_')
          value = instance_variable_get(variable_name)
          hash[attribute] = value.to_s if value
          hash
        end
      end

      private

      def get_formatter(format=nil) #:nodoc:
        case format
          when :svg, nil then Formatter::SvgFormatter.new(self, 2)
          when :xaml then Formatter::XamlFormatter.new(self, 2)
          when :eps then Formatter::EpsFormatter.new(self)
          else raise ArgumentError, "`#{format}' is unknown format"
        end
      end
    end
  end
end
