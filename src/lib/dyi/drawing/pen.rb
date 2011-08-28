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

    class PenBase
      extend AttributeCreator
      DROP_SHADOW_OPTIONS = [:blur_std, :dx, :dy]
      attr_font :font
      attr_reader :drop_shadow

      def initialize(options={})
        @attributes = {}
        @painting = Painting.new
        options.each do |key, value|
          if key.to_sym == :font
            self.font = value
          elsif Painting::IMPLEMENT_ATTRIBUTES.include?(key)
            @painting.__send__("#{key}=", value)
          else
            @attributes[key] = value
          end
        end
      end

      Painting::IMPLEMENT_ATTRIBUTES.each do |painting_attr|
        define_method(painting_attr) {| | @painting.__send__(painting_attr)}
        define_method("#{painting_attr}=".to_sym) {|value|
          @painting = @painting.dup
          @painting.__send__("#{painting_attr}=".to_sym, value)
        }
      end

      def drop_shadow=(options)
        DROP_SHADOW_OPTIONS.each do |key|
          @drop_shadow[key] = options[key.to_sym] if options[key.to_sym]
        end
      end

      def draw_line(canvas, start_point, end_point, options={})
        Shape::Line.create_on_start_end(start_point, end_point, merge_option(options)).draw_on(canvas)
      end

      alias draw_line_on_start_end draw_line

      def draw_line_on_direction(canvas, start_point, direction_x, direction_y, options={})
        Shape::Line.create_on_direction(start_point, direction_x, direction_y, merge_option(options)).draw_on(canvas)
      end

      def draw_polyline(canvas, point, options={}, &block)
        polyline = Shape::Polyline.new(point, merge_option(options))
        yield polyline
        polyline.draw_on(canvas)
      end

      def draw_polygon(canvas, point, options={}, &block)
        polygon = Shape::Polygon.new(point, merge_option(options))
        yield polygon
        polygon.draw_on(canvas)
      end

      def draw_rectangle(canvas, left_top_point, width, height, options={})
        Shape::Rectangle.create_on_width_height(left_top_point, width, height, merge_option(options)).draw_on(canvas)
      end

      alias draw_rectangle_on_width_height draw_rectangle

      def draw_rectangle_on_corner(canvas, top, right, bottom, left, options={})
        Shape::Rectangle.create_on_corner(top, right, bottom, left, merge_option(options)).draw_on(canvas)
      end

      def draw_path(canvas, point, options={}, &block)
        Shape::Path.draw(point, merge_option(options), &block).draw_on(canvas)
      end

      def draw_closed_path(canvas, point, options={}, &block)
        Shape::Path.draw_and_close(point, merge_option(options), &block).draw_on(canvas)
      end

      def draw_circle(canvas, center_point, radius, options={})
        Shape::Circle.create_on_center_radius(center_point, radius, merge_option(options)).draw_on(canvas)
      end

      def draw_ellipse(canvas, center_point, radius_x, radius_y, options={})
        Shape::Ellipse.create_on_center_radius(center_point, radius_x, radius_y, merge_option(options)).draw_on(canvas)
      end

      # @since 1.0.0
      def draw_image(canvas, left_top_point, width, height, file_path, options={})
        Shape::Image.reference(left_top_point, width, height, file_path, merge_option(options)).draw_on(canvas)
      end

      # @since 1.0.0
      def draw_inline_image(canvas, left_top_point, width, height, file_path, options={})
        Shape::Image.inline(left_top_point, width, height, file_path, merge_option(options)).draw_on(canvas)
      end

      def draw_sector(canvas, center_point, radius_x, radius_y, start_angle, center_angle, options={})
        raise ArgumentError, "center_angle is out of range: #{center_angle}" if center_angle.abs > 360
        center_point = Coordinate.new(center_point)
        radius_x = Length.new(radius_x)
        radius_y = Length.new(radius_y)
        large_arc = (center_angle.abs > 180)

        arc_start_pt = Coordinate.new(radius_x * Math.cos(Math::PI * start_angle / 180), radius_y * Math.sin(Math::PI * start_angle / 180)) + center_point
        arc_end_pt = Coordinate.new(radius_x * Math.cos(Math::PI * (start_angle + center_angle) / 180), radius_y * Math.sin(Math::PI * (start_angle + center_angle) / 180)) + center_point

        draw_path(canvas, center_point, merge_option(options)) {|path|
          path.line_to(arc_start_pt)
          if center_angle.abs > 270
            transit_pt = center_point * 2 - arc_start_pt
            path.arc_to(transit_pt, radius_x, radius_y, 0, true)
            path.arc_to(arc_end_pt, radius_x, radius_y, 0, false)
          else
            path.arc_to(arc_end_pt, radius_x, radius_y, 0, large_arc)
          end
          path.line_to(center_point)
        }
      end

      def draw_text(canvas, point, text, options={})
        Shape::Text.new(point, text, merge_option(options)).draw_on(canvas)
      end

      private

      def merge_option(options)
        {:painting=>@painting, :font=>@font}.merge(options)
      end
    end

    class Pen < PenBase
      #:stopdoc:
      ALIAS_ATTRIBUTES =
        Painting::IMPLEMENT_ATTRIBUTES.inject({}) do |hash, key|
          hash[$'.empty? ? :color : $'.to_sym] = key if key.to_s =~ /^(stroke_|stroke$)/
          hash
        end
      #:startdoc:

      def initialize(options={})
        options = options.dup
        ALIAS_ATTRIBUTES.each do |key, value|
          options[value] = options.delete(key) if options.key?(key) && !options.key?(value)
        end
        options[:stroke] = 'black' unless options.key?(:stroke)
        super
      end

      ALIAS_ATTRIBUTES.each do |key, value|
        alias_method key, value
        alias_method "#{key}=", "#{value}="
      end

      def draw_text(canvas, point, text, options={})
        painting = @painting
        text_painting = Painting.new(painting)
        text_painting.fill = painting.stroke
        text_painting.fill_opacity = painting.stroke_opacity
        text_painting.stroke = nil
        text_painting.stroke_width = nil
        @painting = text_painting
        shape = super
        @painting = painting
        shape
      end

      class << self
        def method_missing(method_name, *args, &block) #:nodoc:
          if method_name.to_s =~ /^([a-z]+)_pen$/
            if options = args.first
              self.new(options.merge(:stroke => $1))
            else
              self.new(:stroke => $1)
            end
          else
            super
          end
        end
      end
    end

    class Brush < PenBase
      #:stopdoc:
      ALIAS_ATTRIBUTES =
        Painting::IMPLEMENT_ATTRIBUTES.inject({}) do |hash, key|
          hash[$'.empty? ? :color : $'.to_sym] = key if key.to_s =~ /^(fill_|fill$)/
          hash
        end
      #:startdoc:

      def initialize(options={})
        options = options.dup
        ALIAS_ATTRIBUTES.each do |key, value|
          options[value] = options.delete(key) if options.key?(key) && !options.key?(value)
        end
        options[:stroke_width] = 0 unless options.key?(:stroke_width)
        options[:fill] = 'black' unless options.key?(:fill)
        super
      end

      ALIAS_ATTRIBUTES.each do |key, value|
        alias_method key, value
        alias_method "#{key}=", "#{value}="
      end

      class << self
        def method_missing(method_name, *args, &block) #:nodoc:
          if method_name.to_s =~ /([a-z]+)_brush/
            if options = args.first
              self.new(options.merge(:fill => $1))
            else
              self.new(:fill => $1)
            end
          else
            super
          end
        end
      end
    end
  end
end
