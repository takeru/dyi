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

#
module DYI

  # Marker object represents a symbol at One or more vertices of the lines.
  #
  # Marker provides some pre-defined shapes and a custom marker defined freely.
  # @since 1.2.0
  class Marker < Element

    attr_reader :view_box, :ref_point, :marker_units, :width, :height, :orient, :shapes, :canvas

    @@predefined_markers = {
        :arrow => {
          :view_box => "0 -3 8 6",
          :ref => [0,0],
          :creator => proc{|painting|
            shape = Shape::Polygon.new([8, 0], :painting => painting)
            shape.line_to([0, -3], [0, 3])
            shape
          }},
        :circle => {
          :view_box => "-5 -5 10 10",
          :ref => [0,0],
          :creator => proc{|painting|
            Shape::Circle.new([0, 0], 5, :painting => painting)
          }},
        :triangle => {
          :view_box => "-5 -5 10 10",
          :ref => [0,0],
          :creator => proc{|painting|
            shape = Shape::Polygon.new([0, -7.775601508], :painting => painting)
            shape.line_to([-6.733868435, 3.887800754], [6.733868435, 3.887800754])
            shape
          }},
        :inverted_triangle => {
          :view_box => "-5 -5 10 10",
          :ref => [0,0],
          :creator => proc{|painting|
            shape = Shape::Polygon.new([0, 7.775601508], :painting => painting)
            shape.line_to([6.733868435, -3.887800754], [-6.733868435, -3.887800754])
            shape
          }},
        :square => {
          :view_box => "-5 -5 10 10",
          :ref => [0,0],
          :creator => proc{|painting|
            Shape::Rectangle.new([-4.461134628, -4.461134628], 8.862269255, 8.862269255, :painting => painting)
          }},
        :rhombus => {
          :view_box => "-5 -5 10 10",
          :ref => [0,0],
          :creator => proc{|painting|
            shape = Shape::Polygon.new([0, -6.266570687], :painting => painting)
            shape.line_to([6.266570687, 0], [0, 6.266570687], [-6.266570687, 0])
            shape
          }}}

    # @overload initialize(marker_type, options = {})
    #   Creates a new pre-defined marker.
    #   @param [Symbol] marker_type a type of the marker. Specifies the
    #     following: +:arrow+, +:circle+, +:triangle+, +:inverted_triangle+,
    #     +:square+, +:rhombus+, +:pentagon+, +:hexagon+
    #   @param [Hash] options a customizable set of options
    #   @option options [Number] :size size of the marker. Specifies the
    #     relative size to line width
    #   @option options [Painting] :painting painting of the marker
    # @overload initialize(shapes, options = {})
    #   Creates a new custom marker.
    #   @param [Shape::Base, Array<Shape::Base>] shapes a shape that represents
    #     marker
    #   @param [Hash] options a customizable set of options
    #   @option options [String] :units a setting to define the coordinate
    #     system of the custom marker.
    #   @option options [Coordinate] :ref_point
    #   @option options [Length] :width
    #   @option options [Length] :height
    #   @option options [Number, nil] :orient
    # @raise [ArgumentError]
    def initialize(shape, options={})
      case shape
      when Symbol
        marker_source = @@predefined_markers[shape]
        @shapes = [marker_source[:creator].call(options[:painting] || {})]
        @view_box = marker_source[:view_box]
        @ref_point = Coordinate.new(marker_source[:ref])
        @marker_units = 'strokeWidth'
        @width = @height = Length.new(options[:size] || 3)
        @orient = options[:orient]
      when Shape
      else
        raise ArgumentError, "argument is a wrong class"
      end
    end

    def set_canvas(canvas)
      if @canvas.nil?
        @canvas = canvas
      elsif @canvas != canvas
        raise Arguments, "the clipping is registered to another canvas"
      end
    end

    def child_elements
      @shapes
    end

    def write_as(formatter, io=$>)
      formatter.write_marker(self, io)
    end
  end
end
