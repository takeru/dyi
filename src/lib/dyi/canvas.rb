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

  class Canvas < GraphicalElement
    IMPLEMENT_ATTRIBUTES = [:view_box, :preserve_aspect_ratio]
    attr_length :width, :height
    attr_reader *IMPLEMENT_ATTRIBUTES
    attr_reader :child_elements
    # @since 1.0.0
    attr_reader :event_listeners, :stylesheets

    def initialize(width, height,
                   real_width = nil, real_height = nil,
                   preserve_aspect_ratio='none', options={})
      self.width = width
      self.height = height
      @view_box = "0 0 #{width} #{height}"
      @preserve_aspect_ratio = preserve_aspect_ratio
      @child_elements = []
      @scripts = []
      @event_listeners = {}
      @stylesheets = []
      @seed_of_id = -1
      @receive_event = false
      self.css_class = options[:class]
      self.real_width = real_width
      self.real_height = real_height
    end

    def real_width
      @real_width || width
    end

    def real_width=(width)
      @real_width = Length.new_or_nil(width)
    end

    def real_height
      @real_height || height
    end

    def real_height=(height)
      @real_height = Length.new_or_nil(height)
    end

    # This method is depricated; use Canvas#root_element?
    # @deprecated
    def root_node?
      msg = [__FILE__, __LINE__, ' waring']
      msg << ' DYI::Canvas#root_node? is depricated; use DYI::Canvas#root_element?'
      warn(msg.join(':'))
      true
    end

    # @since 1.0.0
    def root_element?
      true
    end

    # Returns the canvas where the shape is drawn
    # @return [Canvas] the canvas where the shape is drawn
    # @since 1.0.0
    def canvas
      self
    end

    # @since 1.0.0
    def event_listeners
      @event_listeners ||= {}
    end

    def write_as(formatter, io=$>)
      formatter.write_canvas(self, io)
    end

    def save(file_name, format=nil, options={})
      get_formatter(format).save(file_name, options)
    end

    def puts_in_io(format=nil, io=$>)
      get_formatter(format).puts(io)
    end

    def string(format=nil)
      get_formatter(format).string
    end

    def attributes #:nodoc:
      IMPLEMENT_ATTRIBUTES.inject({}) do |hash, attribute|
        variable_name = '@' + attribute.to_s.split(/(?=[A-Z])/).map{|str| str.downcase}.join('_')
        value = instance_variable_get(variable_name)
        hash[attribute] = value.to_s if value
        hash
      end
    end

    # Create a new id for a descendant element
    # @return [String] new id for a descendant element
    # @since 1.0.0
    def publish_shape_id
      'elm%04d' % (@seed_of_id += 1)
    end

    # @since 1.0.0
    def set_event(event)
      super
      @receive_event = true
    end

    # @return [Boolean] whether event is set to the shape
    # @since 1.0.0
    def receive_event?
      @receive_event
    end

    # @since 1.0.0
    def scripts
      @init_script ? [@init_script].push(*@scripts) : @scripts
    end

    # @since 1.0.0
    def add_script(script)
      @scripts << script
    end

    # @since 1.0.0
    def add_style_sheet(ss)
      @stylesheets << ss
    end

    # @since 1.0.0
    def add_initialize_script(script_substance)
      if @init_script
        @init_script = Script::EcmaScript::EventListener.new(
            @init_script.instance_variable_get(@substance) + script_substance, 'init')
      else
        @init_script = Script::EcmaScript::EventListener.new(script_substance, 'init')
        add_event_listener(:load, @init_script)
      end
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

    private

    def get_formatter(format=nil) #:nodoc:
      case format
        when :svg, nil then Formatter::SvgFormatter.new(self, 2)
        when :xaml then Formatter::XamlFormatter.new(self, 2)
        when :eps then Formatter::EpsFormatter.new(self)
        when :png then Formatter::PngFormatter.new(self)
        else raise ArgumentError, "`#{format}' is unknown format"
      end
    end
  end
end
