# -*- encoding: UTF-8 -*-

# Copyright (c) 2009-2011 Sound-F Co., Ltd. All rights reserved.
#
# Author:: Mamoru Yuo
# Documentation:: Mamoru Yuo
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
# This file provides the DYI::Coordinate class, which provides
# coordinate supports for DYI scripts.  The coordinate represents a
# length in the user coordinate system that is the given distance from the
# origin of the user coordinate system along the relevant axis (the x-axis for
# X coordinates, the y-axis for Y coordinates).
#
# See the documentation to the DYI::Coordinate class for more details
# and examples of usage.
#

module DYI #:nodoc:

  # Class representing a coordinate.  See documentation for the file
  # dyi/coordinate.rb for an overview.
  #
  # == Introduction
  #
  # This class works with two length that mean orthogonal coordinates.  The
  # initial coordinate system has the origin at the top/left with the x-axis
  # pointing to the right and the y-axis pointing down.
  #
  # The equality operator '<tt>==</tt>' does not test equality instance but test
  # equality value of x-coordinate and y-coordinate.
  #
  # == Ways of calculating
  #
  # This class suports following arithmetic operators and methods: <tt>+</tt>,
  # <tt>-</tt>, <tt>*</tt>, <tt>/</tt>, <tt>**</tt>, +#quo+.  The operators
  # '<tt>+</tt>', '<tt>-</tt>' coerced right hand operand into Coordinate, and
  # then calculate.
  #
  # See the documentation to each operators and methods class for details.
  class Coordinate
    @@default_format = '(x,y)'

    attr_reader :x, :y

    # :call-seq:
    # new (x_length, y_length)
    # new (x_number, y_number)
    # new (array)
    # new (coordinate)
    #
    def initialize(*args)
      case args.size
      when 1
        case arg = args.first
        when Coordinate
          @x = arg.x
          @y = arg.y
        when Array
          raise ArgumentError, "wrong number of arguments' size (#{arg.size} for 2)" if arg.size != 2
          @x = Length.new(arg[0])
          @y = Length.new(arg[1])
        else
          raise TypeError, "#{arg.class} can't be coerced into #{self.class}"
        end
      when 2
        @x = Length.new(args[0])
        @y = Length.new(args[1])
      else
        raise ArgumentError, "wrong number of arguments (#{args.size} for #{args.size == 0 ? 1 : 2})"
      end
    end

    ZERO = new(0,0)

    def +@
      self
    end

    def -@
      self.class.new(-@x, -@y)
    end

    def +(other)
      other = self.class.new(other)
      self.class.new(@x + other.x, @y + other.y)
    end

    def -(other)
      other = self.class.new(other)
      self.class.new(@x - other.x, @y - other.y)
    end

    def *(number)
      self.class.new(@x * number, @y * number)
    end

    def **(number)
      self.class.new(@x ** number, @y ** number)
    end

    def quo(number)
      raise TypeError, "#{number.class} can't be coerced into Numeric" unless number.kind_of?(Numeric)
      self.class.new(@x.quo(number.to_f), @y.quo(number.to_f))
    end

    alias / quo

    def zero?
      @x.zero? && @y.zero?
    end

    def nonzero?
      zero? ? nil : self
    end

    def ==(other)
      return false unless other.kind_of?(self.class)
      @x == other.x && @y == other.y
    end

    def abs
      (@x ** 2 + @y ** 2) ** 0.5
    end

    def distance(other)
      (self - other).abs
    end

    def to_user_unit
      self.class.new(@x.to_user_unit, @y.to_user_unit)
    end

    # :call-seq:
    # to_s ()
    # to_s (format)
    # 
    def to_s(format=nil)
      fmts = (format || @@default_format).split('\\\\')
      fmts = fmts.map do |fmt|
        fmt.gsub(/(?!\\x)(.|\G)x/, '\\1' + @x.to_s).gsub(/(?!\\y)(.|\G)y/, '\\1' + @y.to_s).delete('\\')
      end
      fmts.join('\\')
    end

    def inspect #:nodoc:
      "(#{@x.inspect}, #{@y.inspect})"
    end

    class << self

      public

      def new(*args) #:nodoc:
        return args.first if args.size == 1 && args.first.instance_of?(self)
        super
      end


      # Creats and Returns new instance as +new+ method when an argument is not
      # +nil+.  If an argument is +nil+, returns +nil+.
      def new_or_nil(*args)
        (args.size == 1 && args.first.nil?) ? nil : new(*args)
      end

      def orthogonal_coordinates(x, y)
        new(x, y)
      end

      def polar_coordinates(radius, theta)
        new(radius * Math.cos(theta * Math::PI / 180), radius * Math.sin(theta * Math::PI / 180))
      end

      def set_default_format(format)
        if block_given?
          org_format = default_format
          self.default_format = format
          yield
          self.default_format = org_format
          self
        else
          self.default_format = format
        end
      end

      def default_format
        @@default_format
      end

      # Sets format that is used when called to_s.
      #
      # The following format indicators can be used for the format specification
      # character string.
      #
      # +x+:: (x-coordinate placeholder) Placeholder '+x+' is replaced as
      #       x-coordinate.
      # +y+:: (y-coordinate placeholder) Placeholder '+y+' is replaced as
      #       y-coordinate.
      # <tt>\\\\<tt>:: (escape character) Causes the next character to be interpreted
      #                as a literal rather than as a custom format specifier.
      # all other characters:: The character is copied to the result string
      #                        unchanged.
      def default_format=(fromat)
        @@default_format = fromat.dup
      end
    end
  end
end
