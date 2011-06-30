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
# This file provides the DYI::Length class, which provides length
# supports for DYI scripts.  The length is a distance measurement.
#
# See the documentation to the DYI::Length class for more details and
# examples of usage.
#

module DYI #:nodoc:

  # Class representing a length.  See documentation for the file
  # dyi/length.rb for an overview.
  #
  # == Introduction
  #
  # This class works with an amount and a unit.  The lists of unit identifiers
  # matches the list of unit identifiers in CSS: em, ex, px, pt, pc, cm, mm, in
  # and percentages(%).  When a unit is not given, then the length is assumed
  # to be in user units (i.e., a value in the current user coordinate sytem).
  #
  # * As in CSS, the _em_ and _ex_ unit identifiers are relative to the current
  #   font's font-size and x-height, respectively.
  # * One _px_ unit is defined to be equal to one user unit.
  # * 1<em>pt</em> equals 1.25 user units.
  # * 1<em>pc</em> equals 15 user units.
  # * 1<em>mm</em> equals 3.543307 user units.
  # * 1<em>cm</em> equals 35.43307 user units.
  # * 1<em>in</em> equals 90 user units.
  # * For percentage values that are defined to be relative to the size of
  #   parent element.
  #
  # == Ways of comparing and calculating
  #
  # This class include +Comparable+ module, therefore you can use the
  # comparative operators.  In the comparison between DYI::Length
  # objects, the unit of each objects are arranged and it does.  The equality
  # operator '<tt>==</tt>' does not test equality instance but test equality
  # value.
  #
  # This class suports following arithmetic operators and methods: <tt>+</tt>,
  # <tt>-</tt>, <tt>*</tt>, <tt>/</tt>, <tt>%</tt>, <tt>**</tt>, +#div+, +#quo+,
  # +#modulo+.  The operators '<tt>+</tt>', '<tt>-</tt>' coerced right hand
  # operand into Length, and then calculate.
  #
  # See the documentation to each operators and methods class for details.
  #
  # == Examples of use
  #
  #   length1 = DYI::Length.new(10)   # 10 user unit (equals to 10px).
  #   length2 = DYI::Length.new('10') # it is 10px too.
  #   DYI::Length.new('1in') > DYI::Length.new(50)
  #                             # => true, 1in equals 90px.
  #   DYI::Length.new('1in') > DYI::Length.new('2em')
  #                             # => Error, 'em' is not comparable unit.
  #   DYI::Length.new('10cm') == DYI::Length.new('100mm')
  #                             # => true
  class Length
    include Comparable

    # Array of unit that can be used.
    UNITS = ['px', 'pt', '%', 'cm', 'mm', 'in', 'em', 'ex', 'pc']

    @@units = {'px'=>1.0,'pt'=>1.25,'cm'=>35.43307,'mm'=>3.543307,'in'=>90.0,'pc'=>15.0}
    @@default_format = '0.###U'

    # Returns a new DYI::Length object.
    #
    # +length+ is instance of +Numeric+, +String+, or
    # <tt>DYI::Length</tt> class.
    def initialize(length)
      case length
      when Length
        @value = length._num
        @unit = length._unit
      when Numeric
        @value = length
        @unit = nil
      when String
        unless /^\s*(-?[\d]*(?:\d\.|\.\d|\d)[0\d]*)(#{UNITS.join('|')})?\s*$/ =~ length
          raise ArgumentError, "`#{length}' is string that could not be understand"
        end
        __value, __unit = $1, $2
        @value = __value.include?('.') ? __value.to_f : __value.to_i
        @unit = (__unit == 'px' || @value == 0) ? nil : __unit
      else
        raise TypeError, "#{length.class} can't be coerced into Length"
      end
    end

    # This constant is zoro length.
    ZERO = new(0)

    # Returns the receiver's value.
    def +@
      self
    end

    # Returns the receiver's value, negated.
    def -@
      new_length(-@value)
    end

    # Returns a new length which is the sum of the receiver and +other+.
    def +(other)
      other = self.class.new(other)
      if @unit == other._unit
        new_length(@value + other._num)
      else
        self.class.new(to_f + other.to_f)
      end
    end

    # Returns a new length which is the difference of the receiver and +other+.
    def -(other)
      other = self.class.new(other)
      if @unit == other._unit
        new_length(@value - other._num)
      else
        self.class.new(to_f - other.to_f)
      end
    end

    # Returns a new muliplicative length of the receiver by +number+.
    def *(number)
      new_length(@value * number)
    end

    # Raises a length the number power.
    def **(number)
      new_length(@value ** number)
    end

    # Returns a new length which is the result of dividing the receiver by
    # +other+.
    def div(other)
      case other
      when Length
        if @unit == other.unit
          @value.div(other._num)
        else
          to_f.div(other.to_f)
        end
      else
        raise TypeError, "#{other.class} can't be coerced into Length"
      end
    end

    # Return a new length which is the modulo after division of the receiver by
    # +other+.
    def % (other)
      case other
      when Length
        if @unit == other.unit
          new_length(@value % other._num)
        else
          self.class.new(to_f % other.to_f)
        end
      else
        raise TypeError, "#{other.class} can't be coerced into Length"
      end
    end

    # If argument +number+ is a numeric, returns a new divisional length of the
    # receiver by +other+.  If argument +number+ is a length, returns a divisional
    # float of the receiver by +other+.
    #
    #   DYI::Length.new(10) / 4                          # => 2.5px
    #   DYI::Length.new(10) / DYI::Length.new(4) # => 2.5
    def /(number)
      case number
      when Numeric
        new_length(@value.quo(number.to_f))
      when Length
        if @unit == number.unit
          @value.quo(number._num.to_f)
        else
          to_f.quo(number.to_f)
        end
      else
        raise TypeError, "#{number.class} can't be coerced into Numeric or Length"
      end
    end

    alias quo /
    alias modulo %

    def clone #:nodoc:
      raise TypeError, "allocator undefined for Length"
    end

    def dup #:nodoc:
      raise TypeError, "allocator undefined for Length"
    end

    # Returns +true+ if the receiver has a zero length, +false+ otherwise.
    def zero?
      @value == 0
    end

    # Returns +self+ if the receiver is not zero, +nil+ otherwise.
    def nonzero?
      @value == 0 ? nil : self
    end

    # Returns the absolute length of the receiver.
    def abs
      @value >= 0 ? self : -self
    end

    # Returns +-1+, +0+, <tt>+1</tt> or +nil+ depending on whether the receiver
    # is less than, equal to, greater than real or not comparable.
    def <=>(other)
      return nil unless other.kind_of?(Length)
      if @unit == other._unit
        @value <=> other._num
      else
        to_f <=> other.to_f rescue nil
      end
    end

    # Returns the receiver's unit.  If receiver has no unit, returns 'px'.
    def unit
      @unit.nil? ? 'px' : @unit
    end

    # :call-seq:
    # step (limit, step) {|length| ...}
    # step (limit, step)
    #
    # Invokes block with the sequence of length starting at receiver,
    # incremented by +step+ on each call.  The loop finishes when +length+ to be
    # passed to the block is greater than +limit+ (if +step+ is positive) or
    # less than +limit+ (if +step+ is negative).
    #
    # If no block is given, an enumerator is returned instead.
    def step(limit, step)
      if @unit == limit._unit && @unit == step._unit
        self_value, limit_value, step_value = @value, limit._num, step._num
      else
        self_value, limit_value, step_value = to_f, limit.to_f, step.to_f
      end
      enum = Enumerator.new {|y|
        self_value.step(limit_value, step_value) do |value|
          self.new_length(value)
        end
      }
      if block_given?
        enum.each(&proc)
        self
      else
        enum
      end
    end

    # Returns a new length that converted into length of user unit.
    def to_user_unit
      @unit ? self.class.new(to_f) : self
    end

    # Returns a string representing obj.
    #
    # Format string can be specified for the argument.  If no argument is given,
    # +default_format+ of this class is used as format string. About format
    # string, see the documentation to +default_format+ method.
    def to_s(format=nil)
      fmts = (format || @@default_format).split('\\\\')
      fmts = fmts.map do |fmt|
        fmt.gsub(/(?!\\U)(.|\G)U/, '\\1' + @unit.to_s).gsub(/(?!\\u)(.|\G)u/, '\\1' + unit)
      end
      @value.strfnum(fmts.join('\\\\'))
    end

    # Returns amount part of a length converted into given unit as float.  If
    # parameter +unit+ is given, converts into user unit.
    def to_f(unit=nil)
      unless self_ratio = @unit ? @@units[@unit] : 1.0
        raise RuntimeError, "unit `#{@unit}' can not convert into user unit"
      end
      unless param_ratio = unit ? @@units[unit] : 1.0
        if UNITS.include?(unit)
          raise RuntimeError, "unit `#{@unit}' can not convert into user unit"
        else
          raise ArgumentError, "unit `#{@unit}' is unknown unit"
        end
      end
      (@value * self_ratio.quo(param_ratio)).to_f
    end

    def inspect #:nodoc:
      @value.to_s + @unit.to_s
    end

    protected

    def _num #:nodoc:
      @value
    end

    def _unit #:nodoc:
      @unit
    end

    private

    def new_length(value) #:nodoc:
      other = self.class.allocate
      other.instance_variable_set(:@value, value)
      other.instance_variable_set(:@unit, @unit)
      other
    end

    class << self

      public

      def new(*args) #:nodoc:
        return args.first if args.size == 1 && args.first.instance_of?(self)
        super
      end

      # Returns new instance as +new+ method when an argument is not +nil+.
      # If an argument is +nil+, returns +nil+.
      def new_or_nil(*args)
        (args.size == 1 && args.first.nil?) ? nil : new(*args)
      end

      # Returns a coefficient that is used for conversion from any unit into
      # user unit. 
      def unit_ratio(unit)
        raise ArgumentError, "unit `#{unit}' can not convert other unit" unless ratio = @@units[unit.to_s]
        ratio
      end

      # :call-seq:
      # set_default_format (format) {...}
      # set_default_format (format)
      #
      # Invokes block with given +format+ string as default format.  After
      # invokes block, formar format is used.
      #
      # If no block is given, sets default format setring as +default_format=+
      # method.
      def set_default_format(format)
        if block_given?
          org_format = @@default_format
          self.default_format = format
          yield
          @@default_format = org_format
          self
        else
          self.default_format = format
        end
      end

      # Returns format that is used when called to_s. See the documentation to
      # +default_format=+ method too.
      def default_format
        @@default_format
      end

      # Sets format that is used when called to_s.
      #
      # The format string is same as <tt>Numeric#strfnum</tt> format.  See the
      # documentation to <tt>Numeric#strfnum</tt> method.  In addition to
      # place-holder of +strfnum+, following placeholder can be used.
      #
      # +u+:: (unit placeholder) Placeholder '+u+' is replaced as a unit. If
      #       the unit is user unit, '+u+' is repleced as 'px'.
      # +U+:: (unit placeholder) Placeholder '+U+' is replaced as a unit. If
      #       the unit is user unit, '+U+' is replece as empty string.
      def default_format=(fromat)
        @@default_format = fromat.dup
      end
    end
  end
end
