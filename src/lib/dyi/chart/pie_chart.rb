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
      include DYI::Script::EcmaScript::DomLevel2

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
      opt_accessor :data_label_format, {:type => :string, :default => "{?name}"}
      opt_accessor :hide_data_label_ratio, {:type => :float, :default => 0.00}
      opt_accessor :show_baloon, :type => :boolean, :default => true
      opt_accessor :baloon_font, :type => :font
      opt_accessor :baloon_position, {:type => :float, :default => 0.8}
      opt_accessor :baloon_format, :type => :string, :default => "{?name}\n{?value}"
      opt_accessor :baloon_padding, :type => :hash, :default => {}, :keys => [:vertical, :horizontal], :item_type => :length
      opt_accessor :baloon_round, :type => :length, :default => 6
      opt_accessor :baloon_background_color, :type => :color
      opt_accessor :baloon_background_colors, :type => :array, :item_type => :color
      opt_accessor :baloon_border_color, :type => :color
      opt_accessor :baloon_border_colors, :type => :array, :item_type => :color
      opt_accessor :baloon_border_width, :type => :length, :default => 2
      opt_accessor :animation_duration, :type => :float, :default => 0.5
#      opt_accessor :baloon_opacity, :type => :float, :default => 1

      def back_translate_value
        {:dy => (Length.new_or_nil(_3d_settings[:dy]) || chart_radius_y.quo(2))}
      end

      # @since 1.0.0
      def get_baloon_background_color(index)
        (baloon_background_colors && baloon_background_colors[index]) ||
            baloon_background_color ||
            chart_color(index).merge('white', 0.7)
      end

      # @since 1.0.0
      def get_baloon_border_color(index)
        (baloon_border_colors && baloon_border_colors[index]) ||
            baloon_border_color ||
            chart_color(index).merge('black', 0.3)
      end

      private

      def default_center_point #:nodoc:
        margin = [width - chart_radius_x * 2, height - chart_radius_y * 2].min.quo(2)
        Coordinate.new(margin + chart_radius_x, margin + chart_radius_y)
      end

      def default_chart_radius_x #:nodoc:
        [width, height].min * 0.4
      end

      def default_chart_radius_y #:nodoc:
        represent_3d? ? chart_radius_x.quo(2) : chart_radius_x
      end

      def default_legend_point #:nodoc:
        if width - chart_radius_x * 2 < height - chart_radius_y * 2
          Coordinate.new(width * 0.1, chart_radius_y * 2 + (width - chart_radius_x * 2) * 0.8)
        else
          Coordinate.new(chart_radius_x * 2 + (height - chart_radius_y * 2) * 0.8, height * 0.1 + Length.new(10))
        end
      end

      def default_legend_format #:nodoc:
        "{?name}\t{?percent}"
      end

      def create_vector_image #:nodoc:
        super
        if represent_3d?
          brush = Drawing::ColumnBrush.new(back_translate_value.merge(chart_stroke_color ? {:stroke_width => chart_stroke_width, :stroke => chart_stroke_color} : {}))
        else
          brush = Drawing::Brush.new(chart_stroke_color ? {:stroke_width => chart_stroke_width, :stroke => chart_stroke_color, :stroke_miterlimit => chart_stroke_width} : {})
        end
        @chart_canvas = Shape::ShapeGroup.draw_on(@canvas)
        @data_label_canvas = Shape::ShapeGroup.draw_on(@canvas)
        @legend_canvas = Shape::ShapeGroup.draw_on(@canvas)
        @legends = []
        @sectors = []
        draw_legend(data.records, nil)
        total_value = data.inject(0.0) {|sum, record| sum + (record.value || 0)}
        accumulation = 0.0
        accumulations = []
        stop_index = -1
        data.each_with_index do |record, i|
          accumulations.push(accumulation)
          value = record.value
          if value && total_value > (accumulation + value) * 2 && value != 0.0
            brush.color = chart_color(i)
            draw_chart(brush, record, accumulation, total_value, i)
            stop_index = i
          end
          accumulation += value if value
        end
        (data.records_size - 1).downto(stop_index + 1) do |i|
          value = (record = data.records[i]).value
          if value && value != 0.0
            brush.color = chart_color(i)
            draw_chart(brush, record, accumulations[i], total_value, i)
          end
        end
        @sectors.each_with_index do |sector, i|
          @legends.each_with_index do |legend, j|
            if i != j
              sector.parent.add_painting_animation(:to => {:opacity => 0.35},
                                          :duration => animation_duration,
                                          :fill => 'freeze',
                                          :begin_event => Event.mouseover(legend),
                                          :end_event => Event.mouseout(legend))
              sector.parent.add_painting_animation(:to => {:opacity => 1},
                                          :fill => 'freeze',
                                          :begin_event => Event.mouseout(legend))
            end
          end
        end
      end

      def draw_chart(brush, record, accumulation, total_value, index) #:nodoc:
        canvas = Shape::ShapeGroup.draw_on(@chart_canvas)
        value = record.value
        pie_sector = brush.draw_sector(
          canvas,
          center_point,
          chart_radius_x,
          chart_radius_y,
          accumulation * 360.0 / total_value - 90,
          value * 360.0 / total_value)
        @sectors[index] = pie_sector

        if moved_elements && (dr = moved_elements[index])
          canvas.translate(
            chart_radius_x * dr * Math.cos(((accumulation * 2.0 + value) / total_value - 0.5) * Math::PI),
            chart_radius_y * dr * Math.sin(((accumulation * 2.0 + value) / total_value - 0.5) * Math::PI))
        end

        ratio = value.to_f.quo(total_value)
        if show_data_label?
          label_point = Coordinate.new(
            chart_radius_x * (data_label_position + (dr || 0)) * Math.cos(((accumulation * 2.0 + value) / total_value - 0.5) * Math::PI),
            chart_radius_y * (data_label_position + (dr || 0)) * Math.sin(((accumulation * 2.0 + value) / total_value - 0.5) * Math::PI))
          Drawing::Pen.black_pen(:font => data_label_font).draw_text(
            @data_label_canvas,
            center_point + label_point,
            format_string(data_label_format, record, total_value),
            :text_anchor => 'middle')
        end if hide_data_label_ratio < ratio
        draw_baloon(brush, record, accumulation, total_value, index, ratio, pie_sector)
      end

      # @since 1.0.0
      def draw_baloon(brush, record, accumulation, total_value, index, ratio, pie_sector)
        value = record.value
        if show_baloon?
          dr = moved_elements && moved_elements[index]
          baloon_point = Coordinate.new(
              chart_radius_x * (baloon_position + (dr || 0)) *
                  Math.cos(((accumulation * 2.0 + value) / total_value - 0.5) * Math::PI),
              chart_radius_y * (baloon_position + (dr || 0)) *
                  Math.sin(((accumulation * 2.0 + value) / total_value - 0.5) * Math::PI))
          baloon_options = {:text_anchor => 'middle', :show_border => true}
          baloon_options[:vertical_padding] = baloon_padding[:vertical_padding] || 2
          baloon_options[:horizontal_padding] = baloon_padding[:horizontal_padding] || 5
          baloon_options[:background_color] = get_baloon_background_color(index)
          baloon_options[:border_color] = get_baloon_border_color(index)
          baloon_options[:border_width] = baloon_border_width
          baloon_options[:border_rx] = baloon_round
#          baloon_options[:opacity] = baloon_opacity
          text = Drawing::Pen.black_pen(:font => baloon_font, :opacity => 0.0).draw_text(
              @data_label_canvas,
              center_point + baloon_point,
              format_string(data_label_format, record, total_value),
              baloon_options)
          text.add_painting_animation(:to => {:opacity => 1},
                                      :duration => animation_duration,
                                      :fill => 'freeze',
                                      :begin_event => Event.mouseover(pie_sector))
          text.add_painting_animation(:to => {:opacity => 0},
                                      :duration => animation_duration,
                                      :fill => 'freeze',
                                      :begin_event => Event.mouseout(pie_sector))
          if @legends
            text.add_painting_animation(:to => {:opacity => 1},
                                        :duration => animation_duration,
                                        :fill => 'freeze',
                                        :begin_event => Event.mouseover(@legends[index]))
            text.add_painting_animation(:to => {:opacity => 0},
                                        :duration => animation_duration,
                                        :fill => 'freeze',
                                        :begin_event => Event.mouseout(@legends[index]))
          end
        end
      end

      # @since 1.0.0
      def draw_legend(records, shapes=nil)
        legend_canvas.translate(legend_point.x, legend_point.y)
        if show_legend?
          pen = Drawing::Pen.black_pen(:font => legend_font)
          brush = Drawing::Brush.new
          toatal = records.inject(0.0){|sum, record| sum + record.value}
          formats = legend_format.split("\t")
          legend_labels = []
          records.each_with_index do |record, i|
            legend_labels << formats.map do |format|
                               format_string(format, record, toatal)
                             end
          end
          require 'pp'
          max_lengths = legend_labels.inject(Array.new(formats.size, 0)) do |maxs, labels|
                          (0...formats.size).each do |i|
                            maxs[i] = labels[i].bytesize if maxs[i] < labels[i].bytesize
                          end
                          maxs
                        end
          canvas.add_initialize_script(form_legend_labels(legend_canvas))
          records.each_with_index do |record, i|
            y = legend_font_size * (1.2 * (i + 1))
            group = Shape::ShapeGroup.draw_on(legend_canvas)
            @legends << group
            case shapes && shapes[i]
            when Shape::Base
              shapes[i].draw_on(group)
            when NilClass
              brush.color = chart_color(i)
              brush.draw_rectangle(
                group,
                Coordinate.new(legend_font_size * 0.2, y - legend_font_size * 0.8),
                legend_font_size * 0.8,
                legend_font_size * 0.8)
            end
            x = legend_font_size * 0.2 + legend_font_size
            legend_labels[i].each_with_index do |label, j|
              formats[j] =~ /\A\{!(\w)\}/
              case $1
              when 's'
                attrs = {:text_anchor => 'start'}
                pen.draw_text(group, Coordinate.new(x, y), label, attrs)
                x += legend_font_size * max_lengths[j] * 0.5
              when 'm'
                attrs = {:text_anchor => 'middle'}
                x += legend_font_size * max_lengths[j] * 0.25
                pen.draw_text(group, Coordinate.new(x, y), label, attrs)
                x += legend_font_size * max_lengths[j] * 0.25
              when 'e'
                attrs = {:text_anchor => 'end'}
                x += legend_font_size * max_lengths[j] * 0.5
                pen.draw_text(group, Coordinate.new(x, y), label, attrs)
              else
                attrs = {}
                pen.draw_text(group, Coordinate.new(x, y), label, attrs)
                x += legend_font_size * max_lengths[j] * 0.5
              end
            end
          end
        end
      end

      def format_string(format, record, total_value)
        format = format.gsub(/\A\{!(\w)\}/, '')
        result = format.gsub(/\{\?((?![0-9])\w+)(:[^}]*)?\}/){|m|
                   fmt = $2 ? $2[1..-1] : nil
                   if $1 == 'percent'
                     value = record.value.quo(total_value)
                     fmt ||= '0.0%'
                   else
                     value = record.__send__($1)
                   end
                   if fmt
                     case value
                       when Numeric then value.strfnum(fmt)
                       when DateTime, Time then value.strftime(fmt)
                       else fmt % value
                     end
                   else
                     value
                   end
                 }
      end
    end
  end
end
