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
#
# == Overview
#
# This file provides the DYI::Element class, which is abstract base class of
# DYI::Canvas and DYI::Shape::Base.
#
# @since 1.0.0

module DYI #:nodoc:

  class Element
    extend AttributeCreator
    ID_REGEXP = /\A[:A-Z_a-z][\-\.0-9:A-Z_a-z]*\z/

    # Returns id for the element. If the element has no id yet, makes id and
    # returns it.
    # @return [String] id for the element
    def id
      @id ||= canvas && canvas.publish_shape_id
    end

    alias publish_id id

    # Returns id of the element. If the element has no id yet, returns nil.
    # @return [String] id for the element if it has id, nil if not
    def inner_id
      @id
    end

    # Sets id for the element.
    # @param [String] value id for the element
    # @return [String] id that is given
    # @raise [ArgumentError] value is empty or illegal format
    def id=(value)
      # TODO: veryfy that the id is unique.
      raise ArgumentError, "`#{value}' is empty" if value.to_s.size == 0
      raise ArgumentError, "`#{value}' is a illegal id" if value.to_s !~ ID_REGEXP
      @id = value.to_s
    end

    # Returns the canvas where the shape is drawn
    # @return [Canvas] the canvas where the shape is drawn
    def canvas
      current_node = self
      loop do
        return current_node if current_node.nil? || current_node.root_element?
        current_node = current_node.parent
      end
    end

    def child_elements
      []
    end

    def include_external_file?
      false
    end

    # @return [Boolean] whether the element has a URI reference
    def has_uri_reference?
      false
    end
  end

  class GraphicalElement < Element
    attr_reader :css_class
    CLASS_REGEXP = /\A[A-Z_a-z][\-0-9A-Z_a-z]*\z/

    def css_class=(css_class)
      classes = css_class.to_s.split(/\s+/)
      classes.each do |c|
        if c.to_s !~ CLASS_REGEXP
          raise ArgumentError, "`#{c}' is a illegal class-name"
        end
      end
      @css_class = classes.join(' ')
    end

    def css_classes
      css_class.split(/\s+/)
    end

    def add_css_class(css_class)
      if css_class.to_s !~ CLASS_REGEXP
        raise ArgumentError, "`#{css_class}' is a illegal class-name"
      end
      unless css_classes.include?(css_class.to_s)
        @css_class += " #{css_class}"
        css_class
      end
      nil
    end

    def remove_css_class(css_class)
      classes = css_classes
      if classes.delete(css_class.to_s)
        @css_class = classes.join(' ')
        css_class
      else
        nil
      end
    end

    # Returns event listeners that is associated with the element
    def event_listeners
      @event_listeners ||= {}
    end

    # Adds a animation of painting to the element
    # @param [Event] an event that is set to the element
    # @return [void]
    def set_event(event)
      @events ||= []
      @events << event
      publish_id
    end

    # @return [Boolean] whether event is set to the element
    def event_target?
      !(@events.nil? || @events.empty?)
    end

    # Associates the element with a event listener
    # @param [Symbol] event_name a event name
    # @param [Script::SimpleScript|String] event_listener a event listener
    # @return [void]
    def add_event_listener(event_name, event_listener)
      if event_listeners.key?(event_name)
        unless event_listeners[event_name].include?(event_listener)
          event_listeners[event_name] << event_listener
          canvas.add_script(event_listener)
        end
      else
        event_listeners[event_name] = [event_listener]
        canvas.add_script(event_listener)
      end
    end

    # Removes asociation with given event listener
    # @param [Symbol] event_name a event name
    # @param [Script::SimpleScript|String] event_listener a event listener
    # @return [void]
    def remove_event_listener(event_name, event_listener)
      if event_listeners.key?(event_name)
        event_listeners[event_name].delete(event_listener)
      end
    end
  end
end
