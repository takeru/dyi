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
      include DYI::Script::EcmaScript::DomLevel2

      def initialize(canvas, indent=0, level=0, version='1.1')
        super(canvas, indent, level)
        unless ['1.0', '1.1'].include?(@version = version.to_s)
          raise ArgumentError, "version `#{version}' is unknown version"
        end
        @defs = {}
        @text_border_elements = []
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
        @xmlns = {:xmlns => "http://www.w3.org/2000/svg"}
        pre_write
        unless @text_border_elements.empty?
          @canvas.add_initialize_script(draw_text_border(*@text_border_elements))
        end
        attrs = @xmlns.merge(:version => @version,
                             :width => canvas.real_width,
                             :height => canvas.real_height,
                             :viewBox => canvas.view_box,
                             :preserveAspectRatio => canvas.preserve_aspect_ratio)
        attrs[:'pointer-events'] = 'none' if canvas.receive_event?
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
            if script.include_external_file?
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
                  while !script.has_uri_reference? && content_type == script.content_type
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
        if @defs.empty? && !@canvas.stylesheets.any?{|style| !style.include_external_file?}
          io << sio.string
        else
          sio.rewind
          io << sio.read(@root_info[0])

          _level = @level
          @level = @root_info[1]
          create_node(io, 'defs') {
            @canvas.stylesheets.each do |stylesheet|
              stylesheet.write_as(self, io)
            end
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
        write_node(shape, io, attrs, 'rect')
      end

      def write_circle(shape, io)
        attrs = {:cx=>shape.center.x, :cy=>shape.center.y, :r=>shape.radius}
        attrs.merge!(common_attributes(shape))
        write_node(shape, io, attrs, 'circle')
      end

      def write_ellipse(shape, io)
        attrs = {:cx=>shape.center.x,
                 :cy=>shape.center.y,
                 :rx=>shape.radius_x,
                 :ry=>shape.radius_y}
        attrs.merge!(common_attributes(shape))
        write_node(shape, io, attrs, 'ellipse')
      end

      def write_line(shape, io)
        attrs = {:x1 => shape.start_point.x,
                 :y1 => shape.start_point.y,
                 :x2 => shape.end_point.x,
                 :y2 => shape.end_point.y}
        attrs.merge!(common_attributes(shape))
        write_node(shape, io, attrs, 'line')
      end

      def write_polyline(shape, io)
        attrs = {:points => shape.points.join(' ')}
        attrs.merge!(common_attributes(shape))
        write_node(shape, io, attrs, 'polyline')
      end

      def write_polygon(shape, io)
        attrs = {:points => shape.points.join(' ')}
        attrs.merge!(common_attributes(shape))
        write_node(shape, io, attrs, 'polygon')
      end

      def write_path(shape, io)
        attrs = {:d => shape.concise_path_data}
        attrs.merge!(common_attributes(shape))
        write_node(shape, io, attrs, 'path')
      end

      # @since 1.0.0
      def write_image(shape, io)
        attrs = {:x=>shape.left,
                 :y=>shape.top,
                 :width=>shape.width,
                 :height=>shape.height}
        if shape.include_external_file?
          attrs[:'xlink:href'] = shape.file_path
        else
          content_type = shape.attributes[:content_type].to_s
          content_type = if content_type.empty?
                           shape.file_path =~ /\.([^\.]+)\z/
                           case $1
                           when 'png'
                             'image/png'
                           when 'jpg', 'jpeg'
                             'image/jpeg'
                           else
                             'image/svg+xml'
                           end
                         else
                           case content_type
                           when 'svg'
                             'image/svg+xml'
                           when 'png'
                             'image/png'
                           when 'jpeg'
                             'image/jpeg'
                           else
                             content_type
                           end
                         end
          open(shape.file_path, 'rb') {|f|
            content = f.read
            attrs[:'xlink:href'] = 
                ['data:', content_type, ";base64,\n", [content].pack('m')[0..-2]].join
          }
        end
        attrs.merge!(common_attributes(shape))
        attrs.reject! do |key, value|
          key.to_s =~ /^(fill|stroke)/
        end
        attrs[:preserveAspectRatio] = shape.attributes[:preserve_aspect_ratio] || 'none'
        write_node(shape, io, attrs, 'image')
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
        if text =~ /(\r\n|\n|\r)/ ||  shape.animate? || shape.attributes[:show_border]
          shape.publish_id if shape.attributes[:show_border]
          create_text_group = proc {|tag_name, attrs|
            create_node(io, tag_name, attrs) {
              create_border_node(shape, io)
              line_number = 0
              txt_attrs = {:x => shape.point.x, :y => shape.point.y}
              # FIXME: Implementation of baseline attribute are not suitable
              case shape.attributes[:alignment_baseline]
                when 'top' then txt_attrs[:y] += shape.font_height * 0.85
                when 'middle' then txt_attrs[:y] += shape.font_height * 0.35
                when 'bottom' then txt_attrs[:y] -= shape.font_height * 0.15
              end
              txt_attrs[:id] = shape.id + '_%02d' % line_number if shape.inner_id
              current_line = $` || text
              create_leaf_node(io, 'text', current_line.strip, txt_attrs)
              $'.each_line do |line|
                line_number += 1
                txt_attrs = {:x => txt_attrs[:x], :y => txt_attrs[:y] + shape.dy}
                txt_attrs[:id] = shape.id + '_%02d' % line_number if shape.inner_id
                create_leaf_node(io, 'text', line.strip, txt_attrs)
              end if $'
              write_animations(shape, io)
            }
          }
          if shape.anchor_href
            attrs[:'xlink:href'] = shape.anchor_href
            attrs[:target] = shape.anchor_target if shape.anchor_target
            create_text_group.call('a', attrs)
          else
            create_text_group.call('g', attrs)
          end
        else
          create_text_group = proc {
            attrs.merge!(:x => shape.point.x, :y => shape.point.y)
            # FIXME: Implementation of baseline attribute are not suitable
            case shape.attributes[:alignment_baseline]
              when 'top' then attrs[:y] += shape.font_height * 0.85
              when 'middle' then attrs[:y] += shape.font_height * 0.35
              when 'bottom' then attrs[:y] -= shape.font_height * 0.15
            end
            create_leaf_node(io, 'text', text, attrs)
          }
          if shape.anchor_href
            link_attrs = {:'xlink:href' => shape.anchor_href}
            link_attrs[:target] = shape.anchor_target if shape.anchor_target
            create_node(io, 'a', link_attrs) {
              create_text_group.call
            }
          else
            create_text_group.call
          end
        end
      end

      def write_group(shape, io)
        unless shape.child_elements.empty?
          attrs = common_attributes(shape)
          write_node(shape, io, attrs, 'g') {
            shape.child_elements.each do |element|
              element.write_as(self, io)
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
        attrs = {:id => clipping.id}
        create_node(io, 'clipPath', attrs) {
          clipping.shapes.each_with_index do |shape, i|
            shape.write_as(self, io)
          end
        }
      end

      # @since 1.0.0
      def write_painting_animation(anim, shape, io)
        anim.animation_attributes.each do |anim_attr, (from_value, to_value)|
          attrs = {:attributeName => name_to_attribute(anim_attr),
                   :attributeType => 'CSS'}
          attrs[:from] = from_value if from_value
          attrs[:to] = to_value
          merge_anim_attributes(anim, shape, attrs)
          if anim.duration && anim.duration != 0
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
        if anim.duration && anim.duration != 0
          create_leaf_node(io, 'animateTransform', attrs)
        else
          create_leaf_node(io, 'set', attrs)
        end
      end

      # @since 1.0.0
      def write_script(script, io)
        if script.include_external_file?
          create_leaf_node(io, 'script',
                           :'xlink:href' => script.href,
                           :type => script.content_type)
        else
          io << script.substance
        end
      end

      # @since 1.0.0
      def write_style(stylesheet, io)
        unless stylesheet.include_external_file?
          attrs = {:type => stylesheet.content_type}
          attrs[:media] = stylesheet.media if stylesheet.media
          attrs[:title] = stylesheet.title if stylesheet.title
          create_cdata_node(io, 'style', attrs){
            io << stylesheet.substance
          }
        end
      end

      private

      # @since 1.0.0
      def write_node(shape, io, attrs, tag_name, &create_child_node)
        if shape.anchor_href
          link_attrs = {:'xlink:href' => shape.anchor_href}
          link_attrs[:target] = shape.anchor_target if shape.anchor_target
          create_node(io, 'a', link_attrs) {
             write_shape_node(shape, io, attrs, tag_name, &create_child_node)
          }
        else
           write_shape_node(shape, io, attrs, tag_name, &create_child_node)
        end
      end

      # @since 1.0.0
      def write_shape_node(shape, io, attrs, tag_name, &create_child_node)
        if shape.animate? || block_given?
          create_node(io, tag_name, attrs) {
            yield if block_given?
            write_animations(shape, io)
          }
        else
          create_leaf_node(io, tag_name, attrs)
        end
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
      def create_border_node(shape, io)
        if shape.attributes[:show_border]
          attrs = {:id => shape.id + '_bd', :x => 0, :y => 0, :width => 0, :height => 0}
          attrs[:rx] = shape.attributes[:border_rx] if shape.attributes[:border_rx]
          attrs[:ry] = shape.attributes[:border_ry] if shape.attributes[:border_ry]
          attrs[:fill] = shape.attributes[:background_color] || Color.new('white')
          attrs[:stroke] = shape.attributes[:border_color] || Color.new('black')
          attrs[:'stroke-width'] = shape.attributes[:border_width] || 1
          create_leaf_node(io, 'rect', attrs)
        end
      end

      # Examines the descendant elements of the canvas to collect the
      # information of the elements.
      # @return [void]
      # @since 1.0.0
      def pre_write
        if @canvas.scripts.any?{|script| script.has_uri_reference?}
          @xmlns[:'xmlns:xlink'] = "http://www.w3.org/1999/xlink"
        end
        examin_descendant_elements(@canvas)
      end

      # @since 1.0.0
      def examin_descendant_elements(element)
        if element.has_uri_reference?
          @xmlns[:'xmlns:xlink'] = "http://www.w3.org/1999/xlink"
        end
        if element.respond_to?(:clipping) && element.clipping
          unless @defs.value?(element.clipping)
            def_id = element.clipping.id
            @defs[def_id] = element.clipping
          end
        end
        if element.respond_to?(:attributes) && element.attributes[:show_border]
          @text_border_elements << element
        end
        element.child_elements.each do |child_element|
          examin_descendant_elements(child_element)
        end
      end

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
          [event.target.id.gsub(/([\.\-\:])/, '\\\\\\1'), event.event_name.to_s].join('.')
        end
      end

      # @since 1.0.0
      def anim_period(shape, event, offset)
        [amin_event(shape, event), anim_duration(offset)].compact.join('+')
      end

      # @return [void]
      # @since 1.0.0
      def merge_anim_attributes(anim, shape, attrs) #:nodoc:
        attrs[:dur] = anim_duration(anim.duration) if anim.duration && anim.duration != 0
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
        attributes[:class] = shape.css_class unless shape.css_class.empty?
        transform = create_transform(shape)
        attributes[:transform] = transform if transform
        attributes[:'clip-path'] = "url(##{shape.clipping.id})" if shape.clipping
        attributes[:id] = shape.id if shape.inner_id
        attributes[:'pointer-events'] = 'all' if shape.event_target?
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

    class PngFormatter
      def save(file_name, options={})
        tmp_svg_file = [file_name, Time.now.strftime('%Y%m%d%H%M%S'), 'tmp'].join('.')
        @svg_formatter.save(tmp_svg_file, options)
        `rsvg-convert -o #{file_name} #{tmp_svg_file}`
        File.delete(tmp_svg_file)
      end

      def string
        tmp_svg_file = [Time.now.strftime('%Y%m%d%H%M%S'), 'tmp'].join('.')
        @svg_formatter.save(tmp_svg_file)
        png_data = `rsvg-convert #{tmp_svg_file}`
        File.delete(tmp_svg_file)
        png_date
      end

      def initialize(*args)
        @svg_formatter = SvgFormatter.new(*args)
      end
    end
  end
end
