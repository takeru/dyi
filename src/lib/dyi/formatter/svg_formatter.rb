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
        unless ['1.0', '1.1'].include?(@version = version.to_s)
          raise ArgumentError, "version `#{version}' is unknown version"
        end
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
        attrs = {:xmlns => "http://www.w3.org/2000/svg",
                 :version => @version,
                 :width => canvas.real_width,
                 :height => canvas.real_height,
                 :viewBox => canvas.view_box,
                 :preserveAspectRatio => canvas.preserve_aspect_ratio}
        if canvas.has_reference?
          attrs[:'xmlns:xlink'] = "http://www.w3.org/1999/xlink"
        end
        attrs[:'pointer-events'] = 'none' if canvas.accept_event?
        canvas.event_listeners.each do |event_name, listeners|
          unless listeners.empty?
            methods = listeners.map do |listener|
                        if listener.name
                          "#{listener.name}(#{listener.arguments.join(',')})"
                        end
                      end
            attrs["on#{event_name}"] = methods.compact.join(';')
          end
        end
        sio = StringIO.new
        create_node(sio, 'svg', attrs) {
          @root_info = [sio.pos, @level]
          i = 0
          length = canvas.scripts.size
          while i < length
            script = canvas.scripts[i]
            if script.has_reference?
              create_leaf_node(sio, 'script',
                               :'xlink:href' => script.href,
                               :type => script.content_type)
              break if length <= (i += 1)
              script = canvas.scripts[i]
            else
              content_type = script.content_type
              create_cdata_node(sio, 'script',
                                :type => content_type) {
                sio << script.substance
                if (i += 1) < length
                  script = canvas.scripts[i]
                  while !script.has_reference? && content_type == script.content_type
                    sio << script.substance
                    break if length <= (i += 1)
                    script = canvas.scripts[i]
                  end
                end
              }
            end
          end
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
        attrs = {:x=>shape.left,
                 :y=>shape.top,
                 :width=>shape.width,
                 :height=>shape.height}
        attrs.merge!(common_attributes(shape))
        attrs[:rx] = shape.attributes[:rx] if shape.attributes[:rx]
        attrs[:ry] = shape.attributes[:ry] if shape.attributes[:ry]
        if shape.animate?
          create_node(io, 'rect', attrs) {
            write_animations(shape, io)
          }
        else
          create_leaf_node(io, 'rect', attrs)
        end
      end

      def write_circle(shape, io)
        attrs = {:cx=>shape.center.x, :cy=>shape.center.y, :r=>shape.radius}
        attrs.merge!(common_attributes(shape))
        if shape.animate?
          create_node(io, 'circle', attrs) {
            write_animations(shape, io)
          }
        else
          create_leaf_node(io, 'circle', attrs)
        end
      end

      def write_ellipse(shape, io)
        attrs = {:cx=>shape.center.x,
                 :cy=>shape.center.y,
                 :rx=>shape.radius_x,
                 :ry=>shape.radius_y}
        attrs.merge!(common_attributes(shape))
        if shape.animate?
          create_node(io, 'ellipse', attrs) {
            write_animations(shape, io)
          }
        else
          create_leaf_node(io, 'ellipse', attrs)
        end
      end

      def write_line(shape, io)
        attrs = {:x1 => shape.start_point.x,
                 :y1 => shape.start_point.y,
                 :x2 => shape.end_point.x,
                 :y2 => shape.end_point.y}
        attrs.merge!(common_attributes(shape))
        if shape.animate?
          create_node(io, 'line', attrs) {
            write_animations(shape, io)
          }
        else
          create_leaf_node(io, 'line', attrs)
        end
      end

      def write_polyline(shape, io)
        attrs = {:points => shape.points.join(' ')}
        attrs.merge!(common_attributes(shape))
        if shape.animate?
          create_node(io, 'polyline', attrs) {
            write_animations(shape, io)
          }
        else
          create_leaf_node(io, 'polyline', attrs)
        end
      end

      def write_polygon(shape, io)
        attrs = {:points => shape.points.join(' ')}
        attrs.merge!(common_attributes(shape))
        if shape.animate?
          create_node(io, 'polygon', attrs) {
            write_animations(shape, io)
          }
        else
          create_leaf_node(io, 'polygon', attrs)
        end
      end

      def write_path(shape, io)
        attrs = {:d => shape.concise_path_data}
        attrs.merge!(common_attributes(shape))
        if shape.animate?
          create_node(io, 'path', attrs) {
            write_animations(shape, io)
          }
        else
          create_leaf_node(io, 'path', attrs)
        end
      end

      def write_text(shape, io)
        attrs = common_attributes(shape)
        if shape.attributes[:text_decoration]
          attrs[:"text-decoration"] = shape.attributes[:text_decoration]
        end
        if shape.attributes[:text_anchor]
          attrs[:"text-anchor"] = shape.attributes[:text_anchor]
        end
        if shape.attributes[:writing_mode]
          attrs[:"writing-mode"] = shape.attributes[:writing_mode]
        end
        if shape.attributes[:textLength]
          attrs[:textLength] = shape.attributes[:textLength]
        end
        if shape.attributes[:lengthAdjust]
          attrs[:lengthAdjust] = shape.attributes[:lengthAdjust]
        end

        text = shape.formated_text
        if text =~ /(\r\n|\n|\r)/ ||  shape.animate?
          create_node(io, 'g', attrs) {
            line_number = 0
            attrs = {:x => shape.point.x, :y => shape.point.y}
            # FIXME: Implementation of baseline attribute are not suitable
            case shape.attributes[:alignment_baseline]
              when 'top' then attrs[:y] += shape.font_height * 0.85
              when 'middle' then attrs[:y] += shape.font_height * 0.35
              when 'bottom' then attrs[:y] -= shape.font_height * 0.15
            end
            attrs[:id] = shape.id + '_%02d' % line_number if shape.inner_id
            create_leaf_node(io, 'text', $`.strip, attrs)
            $'.each_line do |line|
              line_number += 1
              attrs = {:x => attrs[:x], :y => attrs[:y] + shape.dy}
              attrs[:id] = shape.id + '_%02d' % line_number if shape.inner_id
              create_leaf_node(io, 'text', line.strip, attrs)
            end
            write_animations(shape, io)
          }
        else
          attrs.merge!(:x => shape.point.x, :y => shape.point.y)
          create_leaf_node(io, 'text', text, attrs)
        end
      end

      def write_group(shape, io)
        unless shape.child_elements.empty?
          create_node(io, 'g', common_attributes(shape)) {
            shape.child_elements.each do |element|
              element.write_as(self, io)
              write_animations(shape, io)
            end
          }
        end
      end

      def write_linear_gradient(shape, io)
        attrs = {:id => @defs.find{|key, value| value==shape}[0],
                 :gradientUnit => 'objectBoundingBox',
                 :x1 => shape.start_point[0],
                 :y1 => shape.start_point[1],
                 :x2 => shape.stop_point[0],
                 :y2 => shape.stop_point[1]}
        attrs[:"spreadMethod"] = shape.spread_method if shape.spread_method
        create_node(io, 'linearGradient', attrs) {
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
        attrs = {:id => @defs.find{|key, value| value==clipping}[0]}
        create_node(io, 'clipPath', attrs) {
          clipping.shapes.each_with_index do |shape, i|
            shape.write_as(self, io)
          end
        }
      end

      # @since 1.0.0
      def write_animations(shape, io)
        if shape.animate?
          shape.animations.each do |anim|
            anim.write_as(self, shape, io)
          end
        end
      end

      # @since 1.0.0
      def write_painting_animation(anim, shape, io)
        anim.animation_attributes.each do |anim_attr, (from_value, to_value)|
          attrs = {:attributeName => name_to_attribute(anim_attr),
                   :attributeType => 'CSS'}
          attrs[:from] = from_value if from_value
          attrs[:to] = to_value
          merge_anim_attributes(anim, shape, attrs)
          if anim.duration
            create_leaf_node(io, 'animate', attrs)
          else
            create_leaf_node(io, 'set', attrs)
          end
        end
      end

      # @since 1.0.0
      def write_transform_animation(anim, shape, io)
        attrs = {:attributeName => 'transform',
                 :attributeType => 'XML',
                 :type => anim.type}
        if anim.from.is_a?(Array)
          attrs[:from] = anim.from.join(',')
        elsif anim.from
          attrs[:from] = anim.from.to_s
        end
        attrs[:to] = anim.to.is_a?(Array) ? anim.to.join(',') : anim.to.to_s
        merge_anim_attributes(anim, shape, attrs)
        if anim.duration
          create_leaf_node(io, 'animateTransform', attrs)
        else
          create_leaf_node(io, 'set', attrs)
        end
      end

      # @since 1.0.0
      def write_inline_script(script, io)
        io << script.substance
      end

      # @since 1.0.0
      def write_external_script(script, io)
        create_leaf_node(io, 'script',
                         :'xlink:href' => script.href,
                         :type => script.content_type)
      end

      private

      # @since 1.0.0
      def anim_duration(timecount)
        return nil if timecount.nil? || timecount < 0
        return '0s' if timecount == 0
        timecount_ms = (timecount * 1000).to_i
        if timecount_ms % (1000 * 60 * 60) == 0
          '%ih' % (timecount_ms / (1000 * 60 * 60))
        elsif timecount_ms % (1000 * 60) == 0
          '%imin' % (timecount_ms / (1000 * 60))
        elsif timecount_ms % 1000 == 0
          '%is' % (timecount_ms / 1000)
        else
          '%ims' % timecount_ms
        end
      end

      # @since 1.0.0
      def amin_event(shape, event)
        return nil unless event
        if shape && shape == event.target
          event.event_name.to_s
        else
          [event.target.id, event.event_name.to_s].join('.')
        end
      end

      def anim_period(shape, event, offset)
        [amin_event(shape, event), anim_duration(offset)].compact.join('+')
      end

      # @return [void]
      # @since 1.0.0
      def merge_anim_attributes(anim, shape, attrs) #:nodoc:
        attrs[:dur] = anim_duration(anim.duration) if anim.duration
        if anim.begin_event || anim.begin_offset
          attrs[:begin] = anim_period(shape, anim.begin_event, anim.begin_offset)
        else
          attrs[:begin] = '0s'
        end
        if anim.end_event || anim.end_offset
          attrs[:end] = anim_period(shape, anim.end_event, anim.end_offset)
        end
        attrs[:fill] = anim.fill if anim.fill
        attrs[:additive] = anim.additive if anim.additive
        attrs[:restart] = anim.restart if anim.restart
      end

      def name_to_attribute(name) #:nodoc:
        name.to_s.gsub(/_/,'-').to_sym
      end

      def common_attributes(shape) #:nodoc:
        attributes = {}
        create_style(shape, attributes)
        transform = create_transform(shape)
        clip_path = create_clip_path(shape)
        attributes[:transform] = transform if transform
        attributes[:'clip-path'] = clip_path if clip_path
        attributes[:id] = shape.id if shape.inner_id
        attributes[:'pointer-events'] = 'all' if shape.accept_event?
        attributes
      end

      def create_style(shape, attributes) #:nodoc:
        styles = {}
        if shape.font && !shape.font.empty?
          styles.merge!(shape.font.attributes)
        end
        if shape.painting && !shape.painting.empty?
          painting_attrs = shape.painting.attributes
          if painting_attrs.key?(:stroke_dasharray)
            painting_attrs[:stroke_dasharray] =
                painting_attrs[:stroke_dasharray].join(',')
          end
          painting_attrs[:fill] = 'none' unless painting_attrs.key?(:fill)
          styles.merge!(painting_attrs)
        end
        styles.each do |key, value|
          attributes[attribute_name(key)] = attribute_string(value)
        end
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
