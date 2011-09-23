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

require 'csv'

module DYI #:nodoc:
  module Chart #:nodoc:

    module OptionCreator

      # Difines a read property.
      # @param [Symbol] name the property name
      # @param [Hash] settings settings of the property
      # @return [void]
      def opt_reader(name, settings = {})
        name = name.to_sym
        getter_name = settings[:type] == :boolean ? name.to_s.gsub(/^(.*[^=\?])[=\?]*$/, '\1?') : name
        if settings.key?(:default)
          define_method(getter_name) {@options.key?(name) ? @options[name] : settings[:default]}
        elsif settings.key?(:default_method)
          define_method(getter_name) {@options.key?(name) ? @options[name] : __send__(settings[:default_method])}
        elsif settings.key?(:default_proc)
          define_method(getter_name) {@options.key?(name) ? @options[name] : settings[:default_proc].call(self)}
        else
          define_method(getter_name) {@options[name]}
        end
      end

      # Difines a write property.
      # @param [Symbol] name the property name
      # @param [Hash] settings settings of the property
      # @return [void]
      def opt_writer(name, settings = {})
        name = name.to_sym
        setter_name = name.to_s.gsub(/^(.*[^=\?])[=\?]*$/, '\1=')

        convertor =
          case settings[:type]
            when :boolen then proc {|value| not not value}
            when :string then proc {|value| value.to_s}
            when :symbol then proc {|value| value.to_sym}
            when :integer then proc {|value| value.to_i}
            when :float then proc {|value| value.to_f}
            when :length then proc {|value| Length.new(value)}
            when :point then proc {|value| Coordinate.new(value)}
            when :color then proc {|value| Color.new(value)}
            when :font then proc {|value| Font.new(value)}
            else proc {|value| value} if !settings.key?(:map_method) && !settings.key?(:mapper) && !settings.key?(:item_type)
          end

        validator =
          case settings[:type]
          when :symbol
            if settings.key?(:valid_values)
              proc {|value| raise ArgumentError, "\"#{value}\" is invalid value" unless settings[:valid_values].include?(convertor.call(value))}
            end
          when :integer, :float
            if settings.key?(:range)
              proc {|value| raise ArgumentError, "\"#{value}\" is invalid value" unless settings[:range].include?(convertor.call(value))}
            end
          end

        case settings[:type]
        when :hash
          raise ArgumentError, "keys is not specified" unless settings.key?(:keys)
          define_method(setter_name) {|values|
            if values.nil? || values.empty?
              @options.delete(name)
            else
              @options[name] =
                settings[:keys].inject({}) do |hash, key|
                  hash[key] =
                    if convertor
                      convertor.call(values[key])
                    elsif settings.key?(:map_method)
                      __send__(settings[:map_method], values[key])
                    elsif settings.key?(:mapper)
                      settings[:mapper].call(values[key], self)
                    elsif settings.key?(:item_type)
                      case settings[:item_type]
                        when :boolen then not not values[key]
                        when :string then values[key].to_s
                        when :symbol then values[key].to_sym
                        when :integer then values[key].to_i
                        when :float then values[key].to_f
                        when :length then Length.new(values[key])
                        when :point then Coordinate.new(values[key])
                        when :color then value[key].respond_to?(:format) ? value[key] : Color.new(values[key])
                        when :font then Font.new(values[key])
                        else values[key]
                      end
                    end if values[key]
                  hash
                end
            end
            values
          }
        when :array
          define_method(setter_name) {|values|
            if values.nil? || values.empty?
              @options.delete(name)
            else
              @options[name] =
                Array(values).to_a.map {|item|
                  if convertor
                    convertor.call(item)
                  elsif settings.key?(:map_method)
                    __send__(settings[:map_method], item)
                  elsif settings.key?(:mapper)
                    settings[:mapper].call(item, self)
                  elsif settings.key?(:item_type)
                    case settings[:item_type]
                      when :boolen then not not item
                      when :string then item.to_s
                      when :symbol then item.to_sym
                      when :integer then item.to_i
                      when :float then item.to_f
                      when :length then Length.new(item)
                      when :point then Coordinate.new(item)
                      when :color then item.respond_to?(:write_as) ? item : Color.new_or_nil(item)
                      when :font then Font.new(item)
                      else item
                    end
                  else
                    item
                  end
                }
            end
            values
          }
        else
          define_method(setter_name) {|value|
            if value.nil?
              @options.delete(name)
            else
              validator && validator.call(value)
              @options[name] =
                if convertor
                  convertor.call(value)
                elsif settings.key?(:map_method)
                  __send__(settings[:map_method], value)
                elsif ettings.key?(:mapper)
                  settings[:mapper].call(value, self)
                elsif settings.key?(:item_type)
                  case settings[:item_type]
                    when :boolen then not not value
                    when :string then value.to_s
                    when :symbol then value.to_sym
                    when :integer then value.to_i
                    when :float then value.to_f
                    when :length then Length.new(value)
                    when :point then Coordinate.new(value)
                    when :color then Color.new(value)
                    when :font then Font.new(value)
                    else value
                  end
                else
                  value
                end
            end
            value
          }
        end
      end

      # Difines a read-write property.
      # @param [Symbol] name the property name
      # @param [Hash] settings settings of the property
      # @return [void]
      def opt_accessor(name, settings = {})
        opt_reader(name, settings)
        opt_writer(name, settings)
      end
    end

    class Base
      extend OptionCreator

      DEFAULT_CHART_COLOR = ['#ff0f00', '#ff6600', '#ff9e01', '#fcd202', '#f8ff01', '#b0de09', '#04d215', '#0d8ecf', '#0d52d1', '#2a0cd0', '#8a0ccf', '#cd0d74']
      attr_reader :options, :data, :canvas

      opt_accessor :background_image_url, :type => :string
      opt_accessor :background_image_file, :type => :hash, :default => {}, :keys => [:path, :content_type], :item_type => :string
      opt_accessor :background_image_opacity, :type => :float, :default => 1.0
      opt_accessor :script_body, :type => :string
      opt_accessor :css_body, :type => :string
      opt_accessor :script_files, :type => :array, :item_type => :string
      opt_accessor :css_files, :type => :array, :item_type => :string
      opt_accessor :xsl_files, :type => :array, :item_type => :string
      opt_accessor :canvas_css_class, :type => :string

      def initialize(width, height, options={})
        @canvas = Canvas.new(width, height)
        @options = {}
        options.each do |key, value|
          __send__("#{key}=", value) if respond_to?("#{key}=")
        end
      end

      def width
        @canvas.width
      end

      def width=(width)
        @canvas.width = width
      end

      def height
        @canvas.height
      end

      def height=(height)
        @canvas.height = height
      end

      def set_real_size(width, height)
        @canvas.real_width = Length.new(width)
        @canvas.real_height = Length.new(height)
      end

      def clear_real_size
        @canvas.real_width = nil
        @canvas.real_height = nil
      end

      def load_data(reader)
        @data = reader
        create_vector_image
      end

      def save(file_name, format=nil, options={})
        @canvas.save(file_name, format)
      end

      def puts_in_io(format=nil, io=$>)
        @canvas.puts_in_io(format, io)
      end

      def string(format=nil)
        @canvas.string(format)
      end

      private

      def options #:nodoc:
        @options
      end

      def chart_color(index) #:nodoc:
        if data.has_field?(:color)
          color = Color.new_or_nil(data.records[index].color)
        end
        if color.nil? && respond_to?(:chart_colors) && chart_colors
          color = chart_colors[index]
        end
        color || Color.new(DEFAULT_CHART_COLOR[index % DEFAULT_CHART_COLOR.size])
      end

      # @since 1.0.0
      def create_vector_image #:nodoc:
        @canvas.add_css_class(canvas_css_class) if canvas_css_class && !canvas_css_class.empty?
        @canvas.add_script(script_body) if script_body && !script_body.empty?
        @canvas.add_stylesheet(css_body) if css_body && !css_body.empty?
        script_files && script_files.each do |script_file|
          @canvas.reference_script_file(script_file)
        end
        css_files && css_files.each do |css_file|
          @canvas.reference_stylesheet_file(css_file)
        end
        xsl_files && xsl_files.each do |xsl_file|
          @canvas.reference_stylesheet_file(xsl_file, 'text/xsl')
        end
        brush = Drawing::Brush.new
        brush.opacity = background_image_opacity if background_image_opacity != 1.0
        if background_image_url
          brush.import_image(canvas, [0, 0], width, height, background_image_url)
        end 
        if background_image_file[:path]
          brush.draw_image(canvas, [0, 0], width, height, background_image_file[:path], :content_type=>background_image_file[:content_type])
        end
      end
    end
  end
end
