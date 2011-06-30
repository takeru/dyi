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

    class CubicPen < Pen
      POSITION_TYPE_VALUES = [:baseline, :center, :backline]
      attr_reader :position_type, :background_color, :background_opacity, :dx, :dy

      def initialize(options={})
        self.position_type = options.delete(:position_type)
        self.background_color = options.delete(:background_color)
        self.background_opacity = options.delete(:background_opacity)
        self.dx = options.delete(:dx)
        self.dy = options.delete(:dy)
        super
      end

      def position_type=(value)
        if value.to_s.size != 0
          raise ArgumentError, "\"#{value}\" is invalid position-type" unless POSITION_TYPE_VALUES.include?(value)
          @position_type = value
        else
          @position_type = nil
        end
      end

      def background_color=(color)
        @background_color = Color.new_or_nil(color)
      end

      def background_opacity=(opacity)
        @background_opacity = opacity ? opacity.to_f : nil
      end

      def dx
        @dx || Length.new(24)
      end

      def dx=(value)
        @dx = Length.new_or_nil(value)
      end

      def dy
        @dy || Length.new(-8)
      end

      def dy=(value)
        @dy = Length.new_or_nil(value)
      end

      def brush
        @brush ||= Brush.new(:color => background_color || color, :opacity => background_opacity || nil)
      end

      def draw_line(canvas, start_point, end_point, options={})
        group = Shape::ShapeGroup.new
        draw_background_shape(group, start_point, end_point, options)
        super(group, start_point, end_point, options)
        adjust_z_coordinate(group)
        group.draw_on(canvas)
      end

      def draw_polyline(canvas, point, options={}, &block)
        group = Shape::ShapeGroup.new(options)
        polyline = super(group, point, {}, &block)
        (1...polyline.points.size).each do |i|
          draw_background_shape(group, polyline.points[i-1], polyline.points[i], {})
        end
        polyline = super(group, point, {}, &block)
        adjust_z_coordinate(group)
        group.draw_on(canvas)
      end

      private

      def adjust_z_coordinate(shape) #:nodoc:
        case position_type
          when :center then shape.translate(-dx / 2, -dy / 2)
          when :backline then shape.translate(-dx, -dy)
        end
      end

      def draw_background_shape(canvas, start_point, end_point, options={}) #:nodoc:
        brush.draw_polygon(canvas, start_point, options) {|polygon|
          polygon.line_to(end_point)
          polygon.line_to(Coordinate.new(end_point) + Coordinate.new(dx, dy))
          polygon.line_to(Coordinate.new(start_point) + Coordinate.new(dx, dy))
        }
      end
    end

    class CylinderBrush < Brush

      def initialize(options={})
        self.ry = options.delete(:ry)
        super
      end

      def ry
        @ry || Length.new(8)
      end

      def ry=(value)
        @ry = Length.new_or_nil(value)
      end

      def fill
        @painting.fill
      end

      def fill=(value)
        if @painting.fill != Color.new_or_nil(value)
          @painting.fill = Color.new_or_nil(value)
        end
        value
      end

      alias color fill
      alias color= fill=

      def draw_rectangle(canvas, left_top_point, width, height, options={})
        radius_x = width.quo(2)
        radius_y = ry

        shape = Shape::ShapeGroup.draw_on(canvas)
        top_painting = @painting.dup
        top_painting.fill = top_color
        Shape::Ellipse.create_on_center_radius(Coordinate.new(left_top_point) + [width.quo(2), 0], radius_x, radius_y, merge_option(:painting => top_painting)).draw_on(shape)
        body_painting = @painting.dup
        body_painting.fill = body_gradient(canvas)
        Shape::Path.draw(left_top_point, merge_option(:painting => body_painting)) {|path|
          path.rarc_to([width, 0], radius_x, radius_y, 0, false, false)
          path.rline_to([0, height])
          path.rarc_to([-width, 0], radius_x, radius_y, 0, false, true)
          path.rline_to([0, -height])
        }.draw_on(shape)
        shape
      end

      private

      def body_gradient(canvas) #:nodoc:
        gradient = ColorEffect::LinearGradient.new([0,0],[1,0])
        gradient.add_color(0, color.merge(Color.white, 0.4))
        gradient.add_color(0.3, color.merge(Color.white, 0.65))
        gradient.add_color(0.4, color.merge(Color.white, 0.7))
        gradient.add_color(0.5, color.merge(Color.white, 0.65))
        gradient.add_color(0.7, color.merge(Color.white, 0.4))
        gradient.add_color(1, color)
        gradient
      end

      def top_color #:nodoc:
        color.merge(Color.white, 0.3)
      end
    end

    class ColumnBrush < Brush

      def dy
        @dy || Length.new(16)
      end

      def dy=(value)
        @dy = Length.new_or_nil(value)
      end

      def draw_sector(canvas, center_point, radius_x, radius_y, start_angle, center_angle, options={})
        @fill = color

        start_angle = (center_angle > 0 ? start_angle : (start_angle + center_angle)) % 360
        center_angle = center_angle.abs % 360
        center_point = Coordinate.new(center_point)
        radius_x = Length.new(radius_x)
        radius_y = Length.new(radius_y)
        large_arc = (center_angle > 180)

        arc_start_pt = Coordinate.new(radius_x * Math.cos(Math::PI * start_angle / 180), radius_y * Math.sin(Math::PI * start_angle / 180)) + center_point
        arc_end_pt = Coordinate.new(radius_x * Math.cos(Math::PI * (start_angle + center_angle) / 180), radius_y * Math.sin(Math::PI * (start_angle + center_angle) / 180)) + center_point

        org_opacity = opacity
        if org_color = color
          self.color = color.merge('black', 0.2)
        else
          self.color = 'black'
          self.opacity = 0.2
        end

        if (90..270).include?(start_angle) && center_angle < 180
          draw_polygon(canvas, center_point, options) {|polygon|
            polygon.line_to(center_point + [0, dy])
            polygon.line_to(arc_end_pt + [0, dy])
            polygon.line_to(arc_end_pt)
          }
          draw_polygon(canvas, center_point, options) {|polygon|
            polygon.line_to(center_point + [0, dy])
            polygon.line_to(arc_start_pt + [0, dy])
            polygon.line_to(arc_start_pt)
          }
        else
          draw_polygon(canvas, center_point, options) {|polygon|
            polygon.line_to(center_point + [0, dy])
            polygon.line_to(arc_start_pt + [0, dy])
            polygon.line_to(arc_start_pt)
          }
          draw_polygon(canvas, center_point, options) {|polygon|
            polygon.line_to(center_point + [0, dy])
            polygon.line_to(arc_end_pt + [0, dy])
            polygon.line_to(arc_end_pt)
          }
        end
        if (0..180).include?(start_angle)
          draw_path(canvas, arc_start_pt, options) {|path|
            path.line_to(arc_start_pt + [0, dy])
            if arc_end_pt.y >= center_point.y
              path.arc_to(arc_end_pt + [0, dy], radius_x, radius_y, 0, false)
              path.line_to(arc_end_pt)
              path.arc_to(arc_start_pt, radius_x, radius_y, 0, false, false)
            else
              path.arc_to(center_point + [-(radius_x.abs), dy], radius_x, radius_y, 0, false)
              path.line_to(center_point + [-(radius_x.abs), 0])
              path.arc_to(arc_start_pt, radius_x, radius_y, 0, false, false)
            end
          }
        elsif (270..360).include?(start_angle) && start_angle + center_angle > 360
          draw_path(canvas, center_point + [radius_x.abs, 0], options) {|path|
            path.line_to(center_point + [radius_x.abs, dy])
            if arc_end_pt.y >= center_point.y
              path.arc_to(arc_end_pt + [0, dy], radius_x, radius_y, 0, false)
              path.line_to(arc_end_pt)
              path.arc_to(center_point + [radius_x.abs, 0], radius_x, radius_y, 0, false, false)
            else
              path.arc_to(center_point + [-(radius_x.abs), dy], radius_x, radius_y, 0, false)
              path.line_to(center_point + [-(radius_x.abs), 0])
              path.arc_to(center_point + [radius_x.abs, 0], radius_x, radius_y, 0, false, false)
            end
          }
        end
        self.color = org_color
        self.opacity = org_opacity

        draw_path(canvas, center_point, options) {|path|
          path.line_to(arc_start_pt)
          path.arc_to(arc_end_pt, radius_x, radius_y, 0, large_arc)
          path.line_to(center_point)
        }
      end
    end
  end
end
