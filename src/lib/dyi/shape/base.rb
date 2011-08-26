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

require 'enumerator'

module DYI #:nodoc:
  module Shape #:nodoc:

    class Base < Element
      attr_painting :painting
      attr_font :font
      attr_reader :attributes, :clipping
      attr_reader :parent

      ID_REGEXP = /\A[:A-Z_a-z][0-9:A-Z_a-z]*\z/

      # Draws the shape on a parent element.
      # @param [Element] parent a element that you draw the shape on
      # @return [Shape::Base] receiver itself
      def draw_on(parent)
        raise ArgumentError, "parent is nil" if parent.nil?
        return self if @parent == parent
        raise RuntimeError, "this shape already has a parent" if @parent
        current_node = parent
        loop do
          break if current_node.nil? || current_node.root_element?
          if current_node == self
            raise RuntimeError, "descendants of this shape include itself"
          end
          current_node = current_node.parent
        end
        (@parent = parent).child_elements.push(self)
        self
      end

      # This method is depricated; use Shape::Base#root_element?
      # @deprecated
      def root_node?
        msg = [__FILE__, __LINE__, ' waring']
        msg << ' DYI::Shape::Base#root_node? is depricated; use DYI::Shape::Base#root_element?'
        warn(msg.join(':'))
        false
      end

      # @since 1.0.0
      def root_element?
        false
      end

      # Returns the canvas where the shape is drawn
      # @return [Canvas] the canvas where the shape is drawn
      # @since 1.0.0
      def canvas
        current_node = self
        loop do
          return current_node if current_node.nil? || current_node.root_element?
          current_node = current_node.parent
        end
      end

      def transform
        @transform ||= []
      end

      def translate(x, y=0)
        x = Length.new(x)
        y = Length.new(y)
        return if x.zero? && y.zero?
        lt = transform.last
        if lt && lt.first == :translate
          lt[1] += x
          lt[2] += y
          transform.pop if lt[1].zero? && lt[2].zero?
        else
          transform.push([:translate, x, y])
        end
      end

      def scale(x, y=nil, base_point=Coordinate::ZERO)
        y ||= x
        return if x == 1 && y == 1
        base_point = Coordinate.new(base_point)
        translate(base_point.x, base_point.y) if base_point.nonzero?
        lt = transform.last
        if lt && lt.first == :scale
          lt[1] *= x
          lt[2] *= y
          transform.pop if lt[1] == 1 && lt[2] == 1
        else
          transform.push([:scale, x, y])
        end
        translate(- base_point.x, - base_point.y) if base_point.nonzero?
      end

      def rotate(angle, base_point=Coordinate::ZERO)
        angle %= 360
        return if angle == 0
        base_point = Coordinate.new(base_point)
        translate(base_point.x, base_point.y) if base_point.nonzero?
        lt = transform.last
        if lt && lt.first == :rotate
          lt[1] = (lt[1] + angle) % 360
          transform.pop if lt[1] == 0
        else
          transform.push([:rotate, angle])
        end
        translate(- base_point.x, - base_point.y) if base_point.nonzero?
      end

      def skew_x(angle, base_point=Coordinate::ZERO)
        angle %= 180
        return if angle == 0
        base_point = Coordinate.new(base_point)
        translate(base_point.x, base_point.y) if base_point.nonzero?
        transform.push([:skewX, angle])
        translate(- base_point.x, - base_point.y) if base_point.nonzero?
      end

      def skew_y(angle, base_point=Coordinate::ZERO)
        angle %= 180
        return if angle == 0
        base_point = Coordinate.new(base_point)
        translate(base_point.x, base_point.y) if base_point.nonzero?
        lt = transform.last
        transform.push([:skewY, angle])
        translate(- base_point.x, - base_point.y) if base_point.nonzero?
      end

      def set_clipping(clipping)
        @clipping = clipping
      end

      def clear_clipping
        @clipping = nil
      end

      def set_clipping_shapes(*shapes)
        set_clipping(Drawing::Clipping.new(*shapes))
      end

      # since 1.0.0
      def animations
        @animations ||= []
      end

      # @return [Boolean] whether the shape is animated
      # @since 1.0.0
      def animate?
        !(@animations.nil? || @animations.empty?)
      end

      # Add animation to the shape
      # @param [Animation::Base] animation a animation that the shape is run
      # @return [void]
      # @since 1.0.0
      def add_animation(animation)
        animations << animation
      end

      # Add animation of painting to the shape
      # @param [Hash] options
      # @option options [Painting] :from the starting painting of the animation
      # @option options [Painting] :to the ending painting of the animation
      # @option options [Number] :duration a simple duration in seconds
      # @option options [Number] :begin_offset a offset that determine the
      #                                        animation begin, in seconds
      # @option options [Event] :begin_event an event that determine the
      #                                      animation begin
      # @option options [Number] :end_offset a offset that determine the
      #                                      animation end, in seconds
      # @option options [Event] :end_event an event that determine the
      #                                    animation end
      # @option options [String] :fill `freeze' or `remove'
      # @return [void]
      # @since 1.0.0
      def add_painting_animation(options)
        add_animation(Animation::PaintingAnimation.new(self, options))
      end

      # Add animation of transform to the shape
      #
      # @param [Symbol] type a type of transformation which is to have values
      # @param [Hash] options
      # @option options [Number|Array] :from the starting transform of the animation
      # @option options [Number|Array] :to the ending transform of the animation
      # @option options [Number] :duration a simple duration in seconds
      # @option options [Number] :begin_offset a offset that determine the
      #                                        animation begin, in seconds
      # @option options [Event] :begin_event an event that determine the
      #                                      animation begin
      # @option options [Number] :end_offset a offset that determine the
      #                                      animation end, in seconds
      # @option options [Event] :end_event an event that determine the
      #                                    animation end
      # @option options [String] :fill `freeze' or `remove'
      # @return [void]
      # @since 1.0.0
      def add_transform_animation(type, options)
        add_animation(Animation::TransformAnimation.new(self, type, options))
      end

      # Add animation of painting to the shape
      #
      # @param [Event] an event that is set to the shape
      # @return [void]
      # @since 1.0.0
      def set_event(event)
        super
        canvas.set_event(event)
      end

      private

      def init_attributes(options)
        options = options.clone
        @font = Font.new_or_nil(options.delete(:font))
        @painting = Painting.new_or_nil(options.delete(:painting))
        self.id = options.delete(:id) if options[:id]
        options
      end
    end

    class Rectangle < Base
      attr_length :width, :height

      def initialize(left_top, width, height, options={})
        width = Length.new(width)
        height = Length.new(height)
        @lt_pt = Coordinate.new(left_top)
        @lt_pt += Coordinate.new(width, 0) if width < Length::ZERO
        @lt_pt += Coordinate.new(0, height) if height < Length::ZERO
        @width = width.abs
        @height = height.abs
        @attributes = init_attributes(options)
      end

      def left
        @lt_pt.x
      end

      def right
        @lt_pt.x + width
      end

      def top
        @lt_pt.y
      end

      def bottom
        @lt_pt.y + height
      end

      def center
        @lt_pt + Coordinate.new(width.quo(2), height.quo(2))
      end

      def write_as(formatter, io=$>)
        formatter.write_rectangle(self, io, &(block_given? ? Proc.new : nil))
      end

      class << self

        public

        def create_on_width_height(left_top, width, height, options={})
          new(left_top, width, height, options)
        end

        def create_on_corner(top, right, bottom, left, options={})
          left_top = Coordinate.new([left, right].min, [top, bottom].min)
          width = (Length.new(right) - Length.new(left)).abs
          height = (Length.new(bottom) - Length.new(top)).abs
          new(left_top, width, height, options)
        end
      end
    end

    class Circle < Base
      attr_coordinate :center
      attr_length :radius

      def initialize(center, radius, options={})
        @center = Coordinate.new(center)
        @radius = Length.new(radius).abs
        @attributes = init_attributes(options)
      end

      def left
        @center.x - @radius
      end

      def right
        @center.x + @radius
      end

      def top
        @center.y - @radius
      end

      def bottom
        @center.y + @radius
      end

      def width
        @radius * 2
      end

      def height
        @radius * 2
      end

      def write_as(formatter, io=$>)
        formatter.write_circle(self, io, &(block_given? ? Proc.new : nil))
      end

      class << self

        public

        def create_on_center_radius(center, radius, options={})
          new(center, radius, options)
        end
      end
    end

    class Ellipse < Base
      attr_coordinate :center
      attr_length :radius_x, :radius_y

      def initialize(center, radius_x, radius_y, options={})
        @center = Coordinate.new(center)
        @radius_x = Length.new(radius_x).abs
        @radius_y = Length.new(radius_y).abs
        @attributes = init_attributes(options)
      end

      def left
        @center.x - @radius_x
      end

      def right
        @center.x + @radius_x
      end

      def top
        @center.y - @radius_y
      end

      def bottom
        @center.y + @radius_y
      end

      def width
        @radius_x * 2
      end

      def height
        @radius_y * 2
      end

      def write_as(formatter, io=$>)
        formatter.write_ellipse(self, io, &(block_given? ? Proc.new : nil))
      end

      class << self

        public

        def create_on_center_radius(center, radius_x, radius_y, options={})
          new(center, radius_x, radius_y, options)
        end
      end
    end

    class Line < Base
      attr_coordinate :start_point, :end_point

      def initialize(start_point, end_point, options={})
        @start_point = Coordinate.new(start_point)
        @end_point = Coordinate.new(end_point)
        @attributes = init_attributes(options)
      end

      def left
        [@start_point.x, @end_point.x].min
      end

      def right
        [@start_point.x, @end_point.x].max
      end

      def top
        [@start_point.y, @end_point.y].min
      end

      def bottom
        [@start_point.y, @end_point.y].max
      end

      def write_as(formatter, io=$>)
        formatter.write_line(self, io, &(block_given? ? Proc.new : nil))
      end

      class << self

        public

        def create_on_start_end(start_point, end_point, options={})
          new(start_point, end_point, options)
        end

        def create_on_direction(start_point, direction_x, direction_y, options={})
          start_point = Coordinate.new(start_point)
          end_point = start_point + Coordinate.new(direction_x, direction_y)
          new(start_point, end_point, options)
        end
      end
    end

    class Polyline < Base

      def initialize(start_point, options={})
        @points = [Coordinate.new(start_point)]
        @attributes = init_attributes(options)
      end

      def line_to(point, relative=false)
        @points.push(relative ? current_point + point : Coordinate.new(point))
      end

      def current_point
        @points.last
      end

      def start_point
        @points.first
      end

      def points
        @points.dup
      end

      def undo
        @points.pop if @points.size > 1
      end

      def left
        @points.min {|a, b| a.x <=> b.x}.x
      end

      def right
        @points.max {|a, b| a.x <=> b.x}.x
      end

      def top
        @points.min {|a, b| a.y <=> b.y}.y
      end

      def bottom
        @points.max {|a, b| a.y <=> b.y}.y
      end

      def write_as(formatter, io=$>)
        formatter.write_polyline(self, io, &(block_given? ? Proc.new : nil))
      end
    end

    class Polygon < Polyline

      def write_as(formatter, io=$>)
        formatter.write_polygon(self, io, &(block_given? ? Proc.new : nil))
      end
    end

    class Text < Base
      UNPRIMITIVE_OPTIONS = [:line_height, :alignment_baseline, :format]
      BASELINE_VALUES = ['baseline', 'top', 'middle', 'bottom']
      DEFAULT_LINE_HEIGHT = 1
      attr_coordinate :point
      attr_coordinate :line_height
      attr_accessor :text
      attr_reader :format
      attr_reader *UNPRIMITIVE_OPTIONS

      def initialize(point, text=nil, options={})
        @point = Coordinate.new(point || [0,0])
        @text = text
        @attributes = init_attributes(options)
      end

      def format=(value)
        @format = value && value.to_s
      end

      def font_height
        font.draw_size
      end

      def dy
        font_height * (line_height || DEFAULT_LINE_HEIGHT)
      end

      def formated_text
        if @format
          if @text.kind_of?(Numeric)
            @text.strfnum(@format)
          elsif @text.respond_to?(:strftime)
            @text.strftime(@format)
          else
            @text.to_s
          end
        else
          @text.to_s
        end
      end

      def write_as(formatter, io=$>)
        formatter.write_text(self, io, &(block_given? ? Proc.new : nil))
      end

      private

      def init_attributes(options)
        options = super
        format = options.delete(:format)
        @format = format && format.to_s
        line_height = options.delete(:line_height)
        @line_height = line_height || DEFAULT_LINE_HEIGHT
        options
      end
    end

    class ShapeGroup < Base
      attr_reader :child_elements

      def initialize(options={})
        @attributes = init_attributes(options)
        @child_elements = []
      end

      def width
        Length.new_or_nil(@attributes[:width])
      end

      def height
        Length.new_or_nil(@attributes[:height])
      end

      def write_as(formatter, io=$>)
        formatter.write_group(self, io, &(block_given? ? Proc.new : nil))
      end

      class << self
        public

        def draw_on(canvas, options = {})
          new(options).draw_on(canvas)
        end
      end
    end
  end
end
