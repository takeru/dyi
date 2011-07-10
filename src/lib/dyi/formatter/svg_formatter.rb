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

require 'stringio'

module DYI #:nodoc:
  module Formatter #:nodoc:

    class SvgFormatter < XmlFormatter

      def initialize(canvas, indent=0, level=0, version='1.1')
        super(canvas, indent, level)
        raise ArgumentError, "version `#{version}' is unknown version" unless ['1.0', '1.1'].include?(@version = version.to_s)
        @defs = {}
      end

      def declaration
        case @version
          when '1.0' then %Q{<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.0//EN" "http://www.w3.org/TR/2000/CR-SVG-20001102/DTD/svg-20001102.dtd">}
          when '1.1' then %Q{<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN" "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd">}
        end
      end

      def puts(io=$>)
        StringFormat.set_default_formats(:coordinate => 'x,y') {
          super
        }
      end

      def write_canvas(canvas, io)
        @defs = {}
        sio = StringIO.new
        create_node(sio, 'svg',
            :xmlns => "http://www.w3.org/2000/svg",
            :version => @version,
            :width => canvas.real_width,
            :height => canvas.real_height,
            :viewBox => canvas.view_box,
            :preserveAspectRatio => canvas.preserve_aspect_ratio) {
          @root_info = [sio.pos, @level]
          canvas.child_elements.each do |element|
            element.write_as(self, sio)
          end
        }

        if @defs.empty?
          io << sio.string
        else
          sio.rewind
          io << sio.read(@root_info[0])

          _level = @level
          @level = @root_info[1]
          create_node(io, 'defs') {
            @defs.each do |def_id, def_item|
              def_item.write_as(self, io)
            end
          }
          @level = _level

          io << sio.read
        end
      end

      def write_rectangle(shape, io)
        attrs = {:x=>shape.left, :y=>shape.top, :width=>shape.width, :height=>shape.height}
        attrs.merge!(common_attributes(shape))
        attrs[:rx] = shape.attributes[:rx] if shape.attributes[:rx]
        attrs[:ry] = shape.attributes[:ry] if shape.attributes[:ry]
        create_leaf_node(io, 'rect', attrs)
      end

      def write_circle(shape, io)
        attrs = {:cx=>shape.center.x, :cy=>shape.center.y, :r=>shape.radius}
        attrs.merge!(common_attributes(shape))
        create_leaf_node(io, 'circle', attrs)
      end

      def write_ellipse(shape, io)
        attrs = {:cx=>shape.center.x, :cy=>shape.center.y, :rx=>shape.radius_x, :ry=>shape.radius_y}
        attrs.merge!(common_attributes(shape))
        create_leaf_node(io, 'ellipse', attrs)
      end

      def write_line(shape, io)
        attrs = {:x1 => shape.start_point.x, :y1 => shape.start_point.y, :x2 => shape.end_point.x, :y2 => shape.end_point.y}
        attrs.merge!(common_attributes(shape))
        create_leaf_node(io, 'line', attrs)
      end

      def write_polyline(shape, io)
        attrs = {:points => shape.points.join(' ')}
        attrs.merge!(common_attributes(shape))
        create_leaf_node(io, 'polyline', attrs)
      end

      def write_polygon(shape, io)
        attrs = {:points => shape.points.join(' ')}
        attrs.merge!(common_attributes(shape))
        create_leaf_node(io, 'polygon', attrs)
      end

      def write_path(shape, io)
        attrs = {:d => shape.concise_path_data}
        attrs.merge!(common_attributes(shape))
        create_leaf_node(io, 'path', attrs)
      end

      def write_text(shape, io)
        attrs = {:x => shape.point.x, :y => shape.point.y}
        attrs.merge!(common_attributes(shape))
        attrs[:"text-decoration"] = shape.attributes[:text_decoration] if shape.attributes[:text_decoration]
#        attrs[:"alignment-baseline"] = shape.attributes[:alignment_baseline] if shape.attributes[:alignment_baseline]
        case shape.attributes[:alignment_baseline]
          when 'top' then attrs[:y] += shape.font_height * 0.85
          when 'middle' then attrs[:y] += shape.font_height * 0.35
          when 'bottom' then attrs[:y] -= shape.font_height * 0.15
        end
        attrs[:"text-anchor"] = shape.attributes[:text_anchor] if shape.attributes[:text_anchor]
        attrs[:"writing-mode"] = shape.attributes[:writing_mode] if shape.attributes[:writing_mode]
        attrs[:textLength] = shape.attributes[:textLength] if shape.attributes[:textLength]
        attrs[:lengthAdjust] = shape.attributes[:lengthAdjust] if shape.attributes[:lengthAdjust]
        text = shape.formated_text
        if text =~ /(\r\n|\n|\r)/
          create_node(io, 'text', attrs) {
            create_leaf_node(io, 'tspan', $`.strip, :x => shape.point.x)
            $'.each_line do |line|
              create_leaf_node(io, 'tspan', line.strip, :x => shape.point.x, :dy => shape.dy)
            end
          }
        else
          create_leaf_node(io, 'text', text, attrs)
        end
      end

      def write_group(shape, io)
        create_node(io, 'g', common_attributes(shape)) {
          shape.child_elements.each do |element|
            element.write_as(self, io)
          end
        } unless shape.child_elements.empty?
      end

      def write_linear_gradient(shape, io)
        attr = {
          :id => @defs.find{|key, value| value==shape}[0],
          :gradientUnit => 'objectBoundingBox',
          :x1 => shape.start_point[0],
          :y1 => shape.start_point[1],
          :x2 => shape.stop_point[0],
          :y2 => shape.stop_point[1]}
        attr[:"spreadMethod"] = shape.spread_method if shape.spread_method
        create_node(io, 'linearGradient', attr) {
          shape.child_elements.each do |element|
            element.write_as(self, io)
          end
        }
      end

      def write_gradient_stop(shape, io)
        attrs = {:offset=>shape.offset}
        attrs[:"stop-color"] = shape.color if shape.color
        attrs[:"stop-opacity"] = shape.opacity if shape.opacity
        create_leaf_node(io, 'stop', attrs)
      end

      def write_clipping(clipping, io)
        attr = {:id => @defs.find{|key, value| value==clipping}[0]}
        create_node(io, 'clipPath', attr) {
          clipping.shapes.each_with_index do |shape, i|
            shape.write_as(self, io)
          end
        }
      end

      private

      def name_to_attribute(name) #:nodoc:
        name.to_s.gsub(/_/,'-').to_sym
      end

      def common_attributes(shape) #:nodoc:
        attributes = {}
        style = create_style(shape)
        transform = create_transform(shape)
        clip_path = create_clip_path(shape)
        attributes[:style] = style if style
        attributes[:transform] = transform if transform
        attributes[:'clip-path'] = clip_path if clip_path
        attributes
      end

      def create_style(shape) #:nodoc:
        styles = {}
        if shape.respond_to?(:font) && shape.font && !shape.font.empty?
          styles.merge!(shape.font.attributes)
        end
        if shape.respond_to?(:painting) && shape.painting && !shape.painting.empty?
          attributes = shape.painting.attributes
          attributes[:stroke_dasharray] = attributes[:stroke_dasharray].join(',') if attributes.key?(:stroke_dasharray)
          attributes[:fill] = 'none' unless attributes.key?(:fill)
          styles.merge!(attributes)
        end
        styles.empty? ? nil : styles.map {|key, value| "#{attribute_name(key)}:#{attribute_string(value)}"}.join(';')
      end

      def attribute_string(value) #:nodoc:
        value.respond_to?(:write_as) ? "url(##{add_defs(value)})" : value.to_s
      end

      def create_transform(shape) #:nodoc:
        if shape.respond_to?(:transform) && !shape.transform.empty?
          shape.transform.map{|item| "#{item[0]}(#{item[1...item.size].join(',')})"}.join(' ')
        end
      end

      def create_clip_path(shape) #:nodoc:
        if shape.respond_to?(:clipping) && shape.clipping
          "url(##{add_defs(shape.clipping)})"
        end
      end

      def add_defs(value) #:nodoc:
        @defs.each do |def_id, def_item|
          return def_id if def_item == value
        end
        def_id = create_def_id(@defs.size)
        @defs[def_id] = value
        def_id
      end

      def create_def_id(index) #:nodoc:
        'def%03d' % index
      end

      def attribute_name(key) #:nodoc:
        key.to_s.gsub(/_/,'-')
      end
    end
  end
end
