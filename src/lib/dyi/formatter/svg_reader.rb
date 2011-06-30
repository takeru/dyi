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

require 'rexml/document'

module DYI #:nodoc:
  module Formatter #:nodoc:

    class SvgReader
      class << self
        def read(file_name)
          doc = REXML::Document.new(open(file_name))
          container = DYI::Shape::ShapeGroup.new
          doc.root.elements.each do |element|
            container.child_elements.push(create_shape(element))
          end
          container
        end

        private

        def create_shape(element)
          case element.name
            when 'g' then create_shape_group(element)
            when 'polygon' then create_polygon(element)
            when 'path' then create_path(element)
          end
        end

        def create_shape_group(element)
          group = DYI::Shape::ShapeGroup.new
          element.elements.each do |child|
            child_element = create_shape(child)
            group.child_elements.push(child_element) if child_element
          end
          group
        end

        def create_polygon(element)
          color = DYI::Color.new(element.attributes['fill']) if element.attributes['fill'] != 'none'
          points = element.attributes['points'].split(/\s+/).map {|pt| pt.scan(/-?[\.0-9]+/).map {|s| s.to_f}}
          path = nil
          points.each do |pt|
            if path
              path.line_to(pt)
            else
              path = DYI::Shape::Polygon.new(pt, :painting => {:fill => color})
            end
          end
          path
        end

        def create_path(element)
          color = DYI::Color.new(element.attributes['fill']) if element.attributes['fill'] != 'none'
          pathes = element.attributes['d'].scan(/(M|L|l|H|h|V|v|C|c|z)\s*(\s*(?:\s*,?[\-\.0-9]+)*)/)
          path = nil
          if pathes.first.first == 'M'
            pathes.each do |p_el|
              coors = p_el[1].scan(/-?[\.0-9]+/).map {|s| s.to_f}
              case p_el.first
              when 'M'
                if path
                  path.move_to(coors)
                else
                  path = DYI::Shape::Path.new(coors, :painting => {:fill => color})
                end
              when 'L'
                path.line_to(coors)
              when 'l'
                path.line_to(coors, true)
              when 'H'
    p 'H'
                path.line_to([coors.first, path.current_point.y])
              when 'h'
                path.line_to([coors.first, 0], true)
              when 'V'
    p 'V'
                path.line_to([path.current_point.x, coors.first])
              when 'v'
                path.line_to([0, coors.first], true)
              when 'C'
                path.curve_to([coors[0..1], coors[2..3], coors[4..5]])
              when 'c'
                path.curve_to([coors[0..1], coors[2..3], coors[4..5]], true)
              when 'z'
                path.close_path
              end
            end
          end
          path
        end
      end
    end
  end
end
