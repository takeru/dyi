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
# == Overview
#
# This file provides the classes of animation.  The event becomes effective
# only when it is output by SVG format.

module DYI

  # @since 1.0.0
  module Animation

    # Base class for animation classes.
    # @abstract
    # @attr [Object] from a starting value of the animation
    # @attr [Object] to a ending value of the animation
    # @attr [Numeric] duration a simple duration of the animation
    # @attr [Numeric] begin_offset a offset that determine the animation begin
    # @attr [Event] begin_event an event that determine the element begin
    # @attr [Numeric] end_offset a offset that determine the animation end
    # @attr [Event] end_event an event that determine the element end
    # @attr [String] fill the effect of animation when the animation is over,
    #       either 'freeze' or 'remove'
    # @attr [String] additive a value that means whether or not the animation is
    #       additive, either 'replace' or 'sum'
    # @attr [String] restart a value for the restart, either 'always',
    #       'whenNotActive'or 'never'
    class Base
      IMPLEMENT_ATTRIBUTES = [:from, :to, :duration, :begin_offset,
                              :begin_event, :end_offset, :end_event, :fill,
                              :additive, :restart]
      VALID_VALUES = {
        :fill => ['freeze','remove'],
        :additive => ['replace', 'sum'],
        :restart => ['always', 'whenNotActive', 'never']
      }

      attr_reader *IMPLEMENT_ATTRIBUTES

      VALID_VALUES.each do |attr, valid_values|
        define_method("#{attr.to_s}=") {|value|
          if (value = value.to_s).size == 0
            instance_variable_set("@#{attr}", nil)
          else
            unless VALID_VALUES[attr].include?(value)
              raise ArgumentError, "`#{value}' is invalid #{attr}"
            end
            instance_variable_set("@#{attr}", value)
          end
        }
      end

      def duration=(duration)
        @duration = duration
      end

      def begin_offset=(offset)
        @begin_offset = offset
      end

      def begin_event=(event)
        @begin_event = event
      end

      def end_offset=(offset)
        @end_offset = offset
      end

      def end_event=(event)
        @end_event = event
      end

      # @param [Shape::Base] shape a target element for an animation
      # @param [Hash] options an option for an animation
      def initialize(shape, options)
        raise ArgumentError, "`:to' option is required" unless options.key?(:to)
        @shape = shape
        options.each do |attr, value|
          if IMPLEMENT_ATTRIBUTES.include?(attr.to_sym)
            __send__("#{attr}=", value)
          end
        end
      end
    end

    # Class representing an animation of a painting
    # @attr [Painting] from a starting value of the animation
    # @attr [Painting] to a ending value of the animation
    class PaintingAnimation < Base

      def from=(painting)
        @from = painting && DYI::Painting.new(painting)
      end

      def to=(painting)
        @to = DYI::Painting.new(painting)
      end

      def animation_attributes
        DYI::Painting::IMPLEMENT_ATTRIBUTES.inject({}) do |result, attr|
          from_attr, to_attr = @from && @from.__send__(attr), @to.__send__(attr)
          if to_attr && from_attr != to_attr
            result[attr] = [from_attr, to_attr]
          end
          result
        end
      end

      def write_as(formatter, shape, io=$>)
        formatter.write_painting_animation(self, shape, io,
                                           &(block_given? ? Proc.new : nil))
      end
    end

    # Class representing an animation of transform
    # @attr [Symbol] type a type of transform, either 'translate', 'scale',
    #       'rotate', 'skewX' or 'skewY'
    # @attr [Numeric|Array] from a starting value of the animation
    # @attr [Numeric|Array] to a ending value of the animation
    class TransformAnimation < Base
      IMPLEMENT_ATTRIBUTES = [:type]
      VALID_VALUES = {
        :type => [:translate, :scale, :rotate, :skewX, :skewY]
      }

      attr_reader *IMPLEMENT_ATTRIBUTES

      VALID_VALUES.each do |attr, valid_values|
        define_method("#{attr.to_s}=") {|value|
          if (value = value.to_s).size == 0
            instance_variable_set("@#{attr}", nil)
          else
            unless VALID_VALUES[attr].include?(value)
              raise ArgumentError, "`#{value}' is invalid #{attr}"
            end
            instance_variable_set("@#{attr}", value)
          end
        }
      end

      def from=(value)
        case type
        when :translate
          case value
          when Array
            case value.size
              when 2 then @from = value.map{|v| v.to_f}
              else raise ArgumentError, "illegal size of Array: #{value.size}"
            end
          when Numeric, Length
            @from = [value.to_f, 0]
          when nil
            @from = nil
          else
            raise TypeError, "illegal argument: #{value}"
          end
        when :scale
          case value
          when Array
            case value.size
              when 2 then @from = value.map{|v| v.to_f}
              else raise ArgumentError, "illegal size of Array: #{value.size}"
            end
          when Numeric
            @from = [value.to_f, value.to_f]
          when nil
            @from = nil
          else
            raise TypeError, "illegal argument: #{value}"
          end
        when :rotate, :skewX, :skewY
          @from = value.nil? ? nil : value.to_f
        end
      end

      def to=(value)
        case type
        when :translate
          case value
          when Array
            case value.size
              when 2 then @to = value.map{|v| v.to_f}
              else raise ArgumentError, "illegal size of Array: #{value.size}"
            end
          when Numeric, Length
            @to = [value.to_f, 0]
          else
            raise TypeError, "illegal argument: #{value}"
          end
        when :scale
          case value
          when Array
            case value.size
              when 2 then @to = value.map{|v| v.to_f}
              else raise ArgumentError, "illegal size of Array: #{value.size}"
            end
          when Numeric
            @to = [value.to_f, value.to_f]
          else
            raise TypeError, "illegal argument: #{value}"
          end
        when :rotate, :skewX, :skewY
          @to = value.to_f
        end
      end

      def initialize(shape, type, options)
        @type = type
        super(shape, options)
      end

      def write_as(formatter, shape, io=$>)
        formatter.write_transform_animation(self, shape, io,
                                            &(block_given? ? Proc.new : nil))
      end

      class << self
        def translate(shape, options)
          new(shape, :translate, options)
        end

        def scale(shape, options)
          new(shape, :scale, options)
        end

        def scale(rotate, options)
          new(shape, :rotate, options)
        end

        def skew_x(rotate, options)
          new(shape, :skewX, options)
        end

        def skew_y(rotate, options)
          new(shape, :skewY, options)
        end
      end
    end
  end
end