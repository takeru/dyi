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
  module Drawing

    # @since 0.0.0
    module ColorEffect

      class LinearGradient
        SPREAD_METHODS = ['pad', 'reflect', 'repeat']
        attr_reader :start_point, :stop_point, :spread_method

        def initialize(start_point=[0,0], stop_point=[1,0], spread_method=nil)
          @start_point = start_point
          @stop_point = stop_point
          self.spread_method = spread_method
          @child_elements = []
        end

        def add_color(offset, color)
          @child_elements.push(GradientStop.new(offset, :color => color))
        end

        def add_opacity(offset, opacity)
          @child_elements.push(GradientStop.new(offset, :opacity => opacity))
        end

        def add_color_opacity(offset, color, opacity)
          @child_elements.push(GradientStop.new(offset, :color => color, :opacity => opacity))
        end

        def spread_method=(value)
          raise ArgumentError, "\"#{value}\" is invalid spreadMethod" if value && !SPREAD_METHODS.include?(value)
          @spread_method = value
        end

        def child_elements
          @child_elements.clone
        end

        def color?
          true
        end

        def write_as(formatter, io=$>)
          formatter.write_linear_gradient(self, io)
        end

        class << self

          public

          def simple_gradation(derection, *colors)
            case count = colors.size
            when 0
              nil
            when 1
              Color.new(colors.first)
            else
              case deraction
                when :vertical then obj = new([0,0], [0,1])
                when :horizontal then obj = new([0,0], [1,0])
                when :lowerright then obj = new([0,0], [1,1])
                when :upperright then obj = new([0,1], [1,0])
                else raise ArgumentError, "unknown derection: `#{derection}'"
              end
              colors.each_with_index do |color, i|
                obj.add_color(i.quo(count - 1), color)
              end
              obj
            end
          end
        end
      end

      class GradientStop
        attr_reader :offset, :color, :opacity

        def initialize(offset, options={})
          @offset = offset.to_f
          self.color = options[:color]
          self.opacity = options[:opacity]
        end

        def color=(value)
          @color = Color.new_or_nil(value)
          value
        end

        def opacity=(value)
          @opacity = value ? value.to_f : nil
          value
        end

        def write_as(formatter, io=$>)
          formatter.write_gradient_stop(self, io)
        end
      end
    end
  end
end
