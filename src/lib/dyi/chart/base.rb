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

module DYI #:nodoc:
  module Chart #:nodoc:

    module Legend

      private

      def draw_legend(names, shapes=nil, records=nil, colors=nil) #:nodoc:
        legend_canvas.translate(legend_point.x, legend_point.y)
        if show_legend?
          pen = Drawing::Pen.black_pen(:font => legend_font)
          brush = Drawing::Brush.new
          names.each_with_index do |name, index|
            y = legend_font_size * (1.2 * (index + 1))
            group = Shape::ShapeGroup.draw_on(legend_canvas)
            case shapes && shapes[index]
            when Shape::Base
              shapes[index].draw_on(group)
            when NilClass
              brush.color = colors && colors[index] || chart_color(index)
              brush.draw_rectangle(
                group,
                Coordinate.new(legend_font_size * 0.2, y - legend_font_size * 0.8),
                legend_font_size * 0.8,
                legend_font_size * 0.8)
            end
            pen.draw_text(
              group,
              Coordinate.new(legend_font_size * 0.2 + legend_font_size, y),
              name)
          end
        end
      end

      def legend_font_size #:nodoc:
        legend_font ? legend_font.draw_size : Font::DEFAULT_SIZE
      end

      def default_legend_point #:nodoc:
        Coordinate.new(0,0)
      end

      def default_legend_format #:nodoc:
        "{name}"
      end

      class << self

        private

        def included(klass) #:nodoc:
          klass.__send__(:opt_accessor, :show_legend, :type => :boolean, :default => true)
          klass.__send__(:opt_accessor, :legend_font, :type => :font)
          klass.__send__(:opt_accessor, :legend_format, :type => :string, :default_method => :default_legend_format)
          klass.__send__(:opt_accessor, :legend_point, :type => :point, :default_method => :default_legend_point)
        end
      end
    end

    module AxisUtil

      private

      def moderate_axis(data, axis_length, min=nil, max=nil, scale_count_limit=nil)
        raise ArgumentError, 'no data' if (data = data.flatten.compact).empty?

        axis_length = Length.new(axis_length)
        data_min, data_max = chart_range(data, min, max)

        base_value = base_value(data_min, data_max, min.nil?, max.nil?)
        scale_count_limit ||= (axis_length / Length.new(30)).to_i
        scale_count_limit = 10 if 10 < scale_count_limit
        scale_count_limit = 2 if scale_count_limit < 2
        scale_interval = scale_interval(base_value, data_min, data_max, scale_count_limit)
        min_scale_value = nil
        (base_value + scale_interval).step(data_min, -scale_interval) {|n| min_scale_value = n}
        min ||= (min_scale_value.nil? ? base_value : min_scale_value - scale_interval)
        min_scale_value ||= min + scale_interval
        unless max
          base_value.step(data_max, scale_interval) {|n| max = n}
          max += scale_interval if max < data_max
        end
        {
          :min => min || min_scale_value - scale_interval,
          :max => max,
          :axis_length => axis_length,
          :min_scale_value => min_scale_value,
          :scale_interval => scale_interval
        }
      end

      def top_digit(num, n=1) #:nodoc:
        num.div(10 ** (figures_count(num) - n + 1))
      end

      def suitable_1digit_value(a, b) #:nodoc:
        return a if a == b
        a, b = b, a if a > b
        return 0 if a == 0
        return 5 if a <= 5 && 5 <= b
        return 2 if a <= 2 && 2 <= b
        return 4 if a <= 4 && 4 <= b
        return 6 if a <= 6 && 6 <= b
        8
      end

      def figures_count(num) #:nodoc:
        Math.log10(num).floor
      end

      def base_value(a, b, allow_under=true, allow_over=true) #:nodoc:
        return 0 if a * b <= 0 || a == b
        a, b = -a, -b if negative = (a < 0)
        a, b = b, a if a > b
        return 0 if ((negative && allow_over) || (!negative && allow_under)) &&  a < b * 0.3 
        suitable_value_positive(a, b) * (negative ? -1 : 1)
      end

      def suitable_value_positive(a, b) #:nodoc:
        if figures_count(a) != (dig = figures_count(b))
          return 10 ** dig
        end
        n = 1
        n += 1 while (dig_a = top_digit(a, n)) == (dig_b = top_digit(b, n))
        (suitable_1digit_value(dig_a - dig_a.div(10) * 10 + (dig_a == dig_a.div(10) * 10 ? 0 : 1), dig_b - dig_b.div(10) * 10) + dig_a.div(10) * 10) * (10 ** (dig - figures_count(dig_a)))
      end

      def scale_interval(base_value, data_min, data_max, scale_count_limit) #:nodoc:
        if base_value - data_min < data_max - base_value
          allocate_scale_count = (data_max - base_value).div((data_max - data_min).quo(scale_count_limit))
          scale_interval_base2edge(base_value, data_max, allocate_scale_count)
        else
          allocate_scale_count = (base_value - data_min).div((data_max - data_min).quo(scale_count_limit))
          scale_interval_base2edge(base_value, data_min, allocate_scale_count)
        end
      end

      def scale_interval_base2edge(base_value, edge_value, scale_count_limit) #:nodoc:
        raise ArgumentError, 'base_value should not equal edge_value' if edge_value == base_value
        range = (base_value - edge_value).abs

        top_2_digits = top_digit(range, 2)
        case scale_count_limit.to_i
          when 1
            case top_2_digits
              when 10 then label_range = 10
              when 11..20 then label_range = 20
              when 21..40 then label_range = 40
              when 41..50 then label_range = 50
              when 51..99 then label_range = 100
            end
          when 2
            case top_2_digits
              when 10 then label_range = 5
              when 11..20 then label_range = 10
              when 21..40 then label_range = 20
              when 41..50 then label_range = 25
              when 51..99 then label_range = 50
            end
          when 3
            case top_2_digits
              when 10 then label_range = 4
              when 11..15 then label_range = 5
              when 16..30 then label_range = 10
              when 31..60 then label_range = 20
              when 61..75 then label_range = 25
              when 76..99 then label_range = 40
            end
          when 4
            case top_2_digits
              when 10 then label_range = 2.5
              when 11..15 then label_range = 4
              when 16..20 then label_range = 5
              when 21..40 then label_range = 10
              when 41..80 then label_range = 20
              when 81..99 then label_range = 25
            end
          when 5
            case top_2_digits
              when 10 then label_range = 2
              when 11..12 then label_range = 2.5
              when 13..15 then label_range = 4
              when 16..25 then label_range = 5
              when 26..50 then label_range = 10
              when 51..99 then label_range = 20
            end
          when 6
            case top_2_digits
              when 10..12 then label_range = 2
              when 13..15 then label_range = 2.5
              when 16..20 then label_range = 4
              when 21..30 then label_range = 5
              when 31..60 then label_range = 10
              when 61..99 then label_range = 20
            end
          when 7
            case top_2_digits
              when 10..14 then label_range = 2
              when 15..17 then label_range = 2.5
              when 18..20 then label_range = 4
              when 21..35 then label_range = 5
              when 35..70 then label_range = 10
              when 71..99 then label_range = 20
            end
          when 8
            case top_2_digits
              when 10..16 then label_range = 2
              when 17..20 then label_range = 2.5
              when 21..25 then label_range = 4
              when 26..40 then label_range = 5
              when 41..80 then label_range = 10
              when 81..99 then label_range = 20
            end
          when 9
            case top_2_digits
              when 10..18 then label_range = 2
              when 19..22 then label_range = 2.5
              when 23..30 then label_range = 4
              when 31..45 then label_range = 5
              when 46..90 then label_range = 10
              when 91..99 then label_range = 20
            end
          else
            case top_2_digits
              when 10 then label_range = 1
              when 11..20 then label_range = 2
              when 21..25 then label_range = 2.5
              when 26..30 then label_range = 4
              when 31..50 then label_range = 5
              when 51..99 then label_range = 10
            end
        end
        label_range * (10 ** (figures_count(range) - 1))
      end

      def moderate_sub_axis(data, main_axis_settings, min=nil, max=nil)
        if min && max
          axis_ratio = (max - min).quo(main_axis_settings[:max] - main_axis_settings[:min])
          return {
            :max => max,
            :min => min,
            :min_scale_value => min + (main_axis_settings[:min_scale_value] - main_axis_settings[:min]) * axis_ratio,
            :axis_length => main_axis_settings[:axis_length],
            :scale_interval => main_axis_settings[:scale_interval] * axis_ratio
          }
        end
        scale_count = (main_axis_settings[:max] - main_axis_settings[:min_scale_value]).div(main_axis_settings[:scale_interval]) + (main_axis_settings[:min_scale_value] == main_axis_settings[:min] ? 0 : 1)
        data_min, data_max = chart_range(data, min, max)

        base_value = base_value(data_min, data_max, min.nil?, max.nil?)

        scale_interval = scale_interval(base_value, data_min, data_max, scale_count)
        min_scale_value = nil
        (base_value + scale_interval).step(data_min, -scale_interval) {|n| min_scale_value = n}
        min ||= (min_scale_value.nil? ? base_value : min_scale_value - scale_interval)
        min_scale_value ||= min + scale_interval
        max = scale_interval * scale_count + min

        {
          :min => min || min_scale_value - scale_interval,
          :max => max,
          :axis_length => main_axis_settings[:axis_length],
          :min_scale_value => min_scale_value,
          :scale_interval => scale_interval
        }
      end

      def chart_range(data, min=nil, max=nil)
        data = data.compact.flatten
        if min.nil? && max.nil?
          data_min, data_max = 
            data.inject([nil, nil]) do |(_min, _max), value|
              [value < (_min ||= value) ? value : _min,  (_max ||= value) < value ? value : _max]
            end
        elsif min && max && max < min
          data_min, data_max = max, min
        else
          data_min = min || [data.min, max].min
          data_max = max || [data.max, min].max
        end

        if data_min == data_max
          if data_min > 0
            data_min = 0
          elsif data_max < 0
            data_max = 0
          else
            data_min = 0
            data_max = 100
          end
        end
        [data_min, data_max]
      end

      def value_position_on_chart(chart_margin, axis_settings, value, reverse_direction = false)
        axis_settings[:axis_length] * 
          ((reverse_direction ? (axis_settings[:max] - value) : (value - axis_settings[:min])).to_f / (axis_settings[:max] - axis_settings[:min])) + 
          Length.new(chart_margin)
      end

      def order_position_on_chart(chart_margin, axis_length, count, index, type=:point, renge_width_ratio=0, reverse_direction=false)
        chart_margin = Length.new(chart_margin)
        pos =
            case type
              when :point then index.to_f / (count - 1)
              when :range then (index + 0.5 - renge_width_ratio.to_f / 2) / count
              else raise ArgumentError, "\"#{type}\" is invalid type"
            end
        axis_length * pos + chart_margin
      end

      def round_top_2_digit(max, min) #:nodoc:
        digit = Math.log10([max.abs, min.abs].max).floor - 1
        [max.quo(10 ** digit).ceil * (10 ** digit), min.quo(10 ** digit).floor * (10 ** digit)]
      end

      def min_scale_value(max, min, scale_interval) #:nodoc:
        return scale_interval if min == 0
        if (max_digit = Math.log10(max).to_i) != Math.log10(min).to_i
          base_value = 10 ** max_digit
        elsif max.div(10 ** max_digit) != min.div(10 ** max_digit)
          base_value = 9 * 10 ** max_digit
        else
          range_digit = Math.log10(max - min).floor
          base_value = max.div(10 ** range_digit) * (10 ** range_digit)
        end
        base_value - ((base_value - min).quo(scale_interval).ceil - 1) * scale_interval
      end
    end

    class Base
      DEFAULT_CHART_COLOR = ['#ff0f00', '#ff6600', '#ff9e01', '#fcd202', '#f8ff01', '#b0de09', '#04d215', '#0d8ecf', '#0d52d1', '#2a0cd0', '#8a0ccf', '#cd0d74']
      attr_reader :options, :data, :canvas

      def initialize(width, height, options={})
        @canvas = Drawing::Canvas.new(width, height)
        @options = {}
        options.each do |key, value|
          __send__("#{key}=", value) if respond_to?("#{key}=")
        end
      end

      def width
        @canvas.width
      end

      def width=(width)
        @canvas.width = width
      end

      def height
        @canvas.height
      end

      def height=(height)
        @canvas.height = height
      end

      def set_real_size(width, height)
        @canvas.real_width = Length.new(width)
        @canvas.real_height = Length.new(height)
      end

      def clear_real_size
        @canvas.real_width = nil
        @canvas.real_height = nil
      end

      def load_data(reader)
        @data = reader
        create_vector_image
      end

      def save(file_name, format=nil, options={})
        @canvas.save(file_name, format)
      end

      def puts_in_io(format=nil, io=$>)
        @canvas.puts_in_io(format, io)
      end

      def string(format=nil)
        @canvas.string(format)
      end

      private

      def options #:nodoc:
        @options
      end

      def chart_color(index) #:nodoc:
        if respond_to?(:chart_colors) && chart_colors
          result = chart_colors[index]
        end
        result || DEFAULT_CHART_COLOR[index % DEFAULT_CHART_COLOR.size]
      end

      class << self

        private

        def opt_reader(name, settings = {})
          name = name.to_sym
          getter_name = settings[:type] == :boolean ? name.to_s.gsub(/^(.*[^=\?])[=\?]*$/, '\1?') : name
          if settings.key?(:default)
            define_method(getter_name) {@options.key?(name) ? @options[name] : settings[:default]}
          elsif settings.key?(:default_method)
            define_method(getter_name) {@options.key?(name) ? @options[name] : __send__(settings[:default_method])}
          elsif settings.key?(:default_proc)
            define_method(getter_name) {@options.key?(name) ? @options[name] : settings[:default_proc].call(self)}
          else
            define_method(getter_name) {@options[name]}
          end
        end

        def opt_writer(name, settings = {})
          name = name.to_sym
          setter_name = name.to_s.gsub(/^(.*[^=\?])[=\?]*$/, '\1=')

          convertor =
            case settings[:type]
              when :boolen then proc {|value| not not value}
              when :string then proc {|value| value.to_s}
              when :symbol then proc {|value| value.to_sym}
              when :integer then proc {|value| value.to_i}
              when :float then proc {|value| value.to_f}
              when :length then proc {|value| Length.new(value)}
              when :point then proc {|value| Coordinate.new(value)}
              when :color then proc {|value| Color.new(value)}
              when :font then proc {|value| Font.new(value)}
              else proc {|value| value} if !settings.key?(:map_method) && !settings.key?(:mapper) && !settings.key?(:item_type)
            end

          validator =
            case settings[:type]
            when :symbol
              if settings.key?(:valid_values)
                proc {|value| raise ArgumentError, "\"#{value}\" is invalid value" unless settings[:valid_values].include?(convertor.call(value))}
              end
            when :integer, :float
              if settings.key?(:range)
                proc {|value| raise ArgumentError, "\"#{value}\" is invalid value" unless settings[:range].include?(convertor.call(value))}
              end
            end

          case settings[:type]
          when :hash
            raise ArgumentError, "keys is not specified" unless settings.key?(:keys)
            define_method(setter_name) {|values|
              if values.nil? || values.empty?
                @options.delete(name)
              else
                @options[name] =
                  settings[:keys].inject({}) do |hash, key|
                    hash[key] =
                      if convertor
                        convertor.call(values[key])
                      elsif settings.key?(:map_method)
                        __send__(settings[:map_method], values[key])
                      elsif settings.key?(:mapper)
                        settings[:mapper].call(values[key], self)
                      elsif settings.key?(:item_type)
                        case settings[:item_type]
                          when :boolen then not not values[key]
                          when :string then values[key].to_s
                          when :symbol then values[key].to_sym
                          when :integer then values[key].to_i
                          when :float then values[key].to_f
                          when :length then Length.new(values[key])
                          when :point then Coordinate.new(values[key])
                          when :color then value[key].respond_to?(:format) ? value[key] : Color.new(values[key])
                          when :font then Font.new(values[key])
                          else values[key]
                        end
                      end if values[key]
                    hash
                  end
              end
              values
            }
          when :array
            define_method(setter_name) {|values|
              if values.nil? || values.empty?
                @options.delete(name)
              else
                @options[name] =
                  Array(values).to_a.map {|item|
                    if convertor
                      convertor.call(item)
                    elsif settings.key?(:map_method)
                      __send__(settings[:map_method], item)
                    elsif settings.key?(:mapper)
                      settings[:mapper].call(item, self)
                    elsif settings.key?(:item_type)
                      case settings[:item_type]
                        when :boolen then not not item
                        when :string then item.to_s
                        when :symbol then item.to_sym
                        when :integer then item.to_i
                        when :float then item.to_f
                        when :length then Length.new(item)
                        when :point then Coordinate.new(item)
                        when :color then item.respond_to?(:write_as) ? item : Color.new(item)
                        when :font then Font.new(item)
                        else item
                      end
                    else
                      item
                    end
                  }
              end
              values
            }
          else
            define_method(setter_name) {|value|
              if value.nil?
                @options.delete(name)
              else
                validator && validator.call(value)
                @options[name] =
                  if convertor
                    convertor.call(value)
                  elsif settings.key?(:map_method)
                    __send__(settings[:map_method], value)
                  elsif ettings.key?(:mapper)
                    settings[:mapper].call(value, self)
                  elsif settings.key?(:item_type)
                    case settings[:item_type]
                      when :boolen then not not value
                      when :string then value.to_s
                      when :symbol then value.to_sym
                      when :integer then value.to_i
                      when :float then value.to_f
                      when :length then Length.new(value)
                      when :point then Coordinate.new(value)
                      when :color then Color.new(value)
                      when :font then Font.new(value)
                      else value
                    end
                  else
                    value
                  end
              end
              value
            }
          end
        end

        def opt_accessor(name, settings = {})
          opt_reader(name, settings)
          opt_writer(name, settings)
        end
      end
    end
  end
end
