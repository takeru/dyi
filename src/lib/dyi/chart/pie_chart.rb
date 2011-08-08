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

    class PieChart < Base
      include Legend
      attr_reader :chart_canvas, :data_label_canvas, :legend_canvas

      opt_accessor :center_point, {:type => :point, :default_method => :default_center_point}
      opt_accessor :chart_radius_x, {:type => :length, :default_method => :default_chart_radius_x}
      opt_accessor :chart_radius_y, {:type => :length, :default_method => :default_chart_radius_y}
      opt_accessor :represent_3d, {:type => :boolean}
      opt_accessor :_3d_settings, {:type => :hash, :default => {}, :keys => [:dy], :item_type => :float}
      opt_accessor :chart_colors, {:type => :array, :item_type => :color}
      opt_accessor :chart_stroke_color, {:type => :color}
      opt_accessor :chart_stroke_width, {:type => :float, :default => 1}
      opt_accessor :moved_elements, {:type => :array, :item_type => :float}
      opt_accessor :show_data_label, {:type => :boolean, :default => true}
      opt_accessor :data_label_position, {:type => :float, :default => 0.8}
      opt_accessor :data_label_font, {:type => :font}
      opt_accessor :data_label_format, {:type => :string, :default => "{name}\n{value}"}
      opt_accessor :hide_data_label_ratio, {:type => :float, :default => 0.00}

      def back_translate_value
        {:dy => (Length.new_or_nil(_3d_settings[:dy]) || chart_radius_y.quo(2))}
      end

      private

      def default_center_point #:nodoc:
        Coordinate.new(coordinate = ([width, height].min).quo(2), coordinate)
      end

      def default_chart_radius_x #:nodoc:
        [[width, height].min / 2 - Length.new(32), [width, height].min * 0.4].max
      end

      def default_chart_radius_y #:nodoc:
        represent_3d? ? chart_radius_x.quo(2) : chart_radius_x
      end

      def default_csv_format #:nodoc:
        [:$name, 0, :$color]
      end

      def default_legend_point #:nodoc:
        Coordinate.new(width < height ? [width * 0.1, width] : [height, height * 0.1])
      end

      def default_legend_format #:nodoc:
        "{name}\t{percent}"
      end

      def create_vector_image #:nodoc:
        if represent_3d?
          brush = Drawing::ColumnBrush.new(back_translate_value.merge(chart_stroke_color ? {:stroke_width => chart_stroke_width, :stroke => chart_stroke_color} : {}))
        else
          brush = Drawing::Brush.new(chart_stroke_color ? {:stroke_width => chart_stroke_width, :stroke => chart_stroke_color, :stroke_miterlimit => chart_stroke_width / 2.0} : {})
        end
        @chart_canvas = Shape::ShapeGroup.draw_on(@canvas)
        @data_label_canvas = Shape::ShapeGroup.draw_on(@canvas)
        @legend_canvas = Shape::ShapeGroup.draw_on(@canvas)
        total_value = data.column_values(0).inject(0.0) {|sum, value| sum + (value || 0)}
        accumulation = 0.0
        accumulations = []
        stop_index = -1
        data.column_values(0).each_with_index do |value, i|
          accumulations.push(accumulation)
          if value && total_value > (accumulation + value) * 2 && value != 0.0
#            brush.color = data[:$color] && data[:$color][i] || chart_color(i)
            brush.color = chart_color(i)
            name = data.row_title(i)
            draw_chart(brush, name, value, accumulation, total_value, i)
            stop_index = i
          end
          accumulation += value if value
        end
        (data.column_values(0).size - 1).downto(stop_index + 1) do |i|
          value = data.column_values(0)[i]
          if value && value != 0.0
#            brush.color = data[:$color] && data[:$color][i] || chart_color(i)
            brush.color = chart_color(i)
            name = data.row_title(i)
            draw_chart(brush, name, value, accumulations[i], total_value, i)
          end
        end
#        draw_legend(data.row_titles, nil, nil, data[:$color])
        draw_legend(data.row_titles, nil, nil, nil)
      end

      def draw_chart(brush, name, value, accumulation, total_value, index) #:nodoc:
        canvas = Shape::ShapeGroup.draw_on(@chart_canvas)
        brush.draw_sector(
          canvas,
          center_point,
          chart_radius_x,
          chart_radius_y,
          accumulation * 360.0 / total_value - 90,
          value * 360.0 / total_value)

        if moved_elements && (dr = moved_elements[index])
          canvas.translate(
            chart_radius_x * dr * Math.cos(((accumulation * 2.0 + value) / total_value - 0.5) * Math::PI),
            chart_radius_y * dr * Math.sin(((accumulation * 2.0 + value) / total_value - 0.5) * Math::PI))
        end

        ratio = value.to_f.quo(total_value)
        if show_data_label?
          legend_point = Coordinate.new(
            chart_radius_x * (data_label_position + (dr || 0)) * Math.cos(((accumulation * 2.0 + value) / total_value - 0.5) * Math::PI),
            chart_radius_y * (data_label_position + (dr || 0)) * Math.sin(((accumulation * 2.0 + value) / total_value - 0.5) * Math::PI))
          Drawing::Pen.black_pen(:font => data_label_font).draw_text(
            @data_label_canvas,
            center_point + legend_point,
            data_label_format.gsub(/\{name\}/, name).gsub(/\{value\}/, value.to_s).gsub(/\{percent\}/, '%.1f%' % (ratio * 100.0).to_s),
            :text_anchor => 'middle')
        end if hide_data_label_ratio < ratio
      end
    end
  end
end
