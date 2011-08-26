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
    ID_REGEXP = /\A[:A-Z_a-z][0-9:A-Z_a-z]*\z/

    # Returns id for the shape. If the shape has no id yet, makes id and
    # returns it.
    # @return [String] id for the shape
    def id
      @id ||= canvas && canvas.publish_shape_id
    end

    alias publish_id id

    # Returns id of the shape. If the shape has no id yet, returns nil.
    # @return [String] id for the shape if it has id, nil if not
    def inner_id
      @id
    end

    # Sets id for the shape.
    # @param [String] value id for the shape
    # @return [String] id that is given
    # @raise [ArgumentError] value is empty or illegal format
    def id=(value)
      # TODO: veryfy that the id is unique.
      raise ArgumentError, "`#{value}' is empty" if value.to_s.size == 0
      raise ArgumentError, "`#{value}' is a illegal id" if value.to_s !~ ID_REGEXP
      @id = value.to_s
    end

    # @since 1.0.0
    def event_listeners
      @event_listeners ||= {}
    end

    # Add animation of painting to the shape
    #
    # @param [Event] an event that is set to the shape
    # @return [void]
    # @since 1.0.0
    def set_event(event)
      @events ||= []
      @events << event
      publish_id
    end

    # @return [Boolean] whether event is set to the shape
    # @since 1.0.0
    def event_target?
      !(@events.nil? || @events.empty?)
    end

    # @since 1.0.0
    def add_event_listener(event_name, event_listener)
      if event_listeners.key?(event_name)
        unless event_listeners[event_name].include?(event_listener)
          event_listeners[event_name] << event_listener
        end
      else
        event_listeners[event_name] = [event_listener]
      end
    end

    # @since 1.0.0
    def remove_event_listener(event_name, event_listener)
      if event_listeners.key?(event_name)
        event_listeners[event_name].delete(event_listener)
      end
    end
  end
end
