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
    attr_reader :event_listeners, :stylesheets, :scripts

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
      self.css_class = options[:css_class]
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

    def write_as(formatter, io=$>)
      formatter.write_canvas(self, io)
    end

    def save(file_name, format=nil, options={})
      get_formatter(format, options).save(file_name)
    end

    def puts_in_io(format=nil, io=$>, options={})
      get_formatter(format, options).puts(io)
    end

    def string(format=nil, options={})
      get_formatter(format, options).string
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

    # @overload add_script(script)
    #   Registers a script object with this canvas
    #   @param [Script::SimpleScript] script a script that is registered
    # @overload add_script(script_body, content_type='application/ecmascript')
    #   Registers a script.  Create a script object and Registers it with this
    #   canvas.
    #   @param [String] script_body a string that is script body
    #   @param [String] content_type a content-type of the script
    # @since 1.0.0
    def add_script(script_body, content_type = 'application/ecmascript')
      if script_body.respond_to?(:include_external_file?)
        @scripts << script_body unless @scripts.include?(script_body)
      else
        @scripts << Script::SimpleScript.new(script_body, content_type)
      end
    end

    # @since 1.0.0
    def reference_script_file(reference_path, content_type = 'application/ecmascript')
      @scripts << Script::ScriptReference.new(reference_path, content_type)
    end

    # @since 1.0.0
    def add_stylesheet(style_body, content_type = 'text/css')
      @stylesheets << Stylesheet::Style.new(style_body, content_type)
    end

    # @since 1.0.0
    def reference_stylesheet_file(reference_path, content_type = 'text/css')
      @stylesheets << Stylesheet::StyleReference.new(reference_path, content_type)
    end

    # @since 1.0.0
    def add_initialize_script(script_body)
      if @init_script
        @init_script.append_body(script_body)
      else
        @init_script = Script::EcmaScript::EventListener.new(script_body, 'init')
        add_event_listener(:load, @init_script)
      end
    end

    private

    def get_formatter(format=nil, options={}) #:nodoc:
      case format
        when :svg, nil
          options[:indent] = 2 unless options.key?(:indent)
          Formatter::SvgFormatter.new(self, options)
        when :xaml
          options[:indent] = 2 unless options.key?(:indent)
          Formatter::XamlFormatter.new(self, options)
        when :eps then Formatter::EpsFormatter.new(self)
        when :png then Formatter::PngFormatter.new(self)
        else raise ArgumentError, "`#{format}' is unknown format"
      end
    end
  end
end
