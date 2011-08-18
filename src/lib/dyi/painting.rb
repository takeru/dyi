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

  class Painting
    IMPLEMENT_ATTRIBUTES = [:fill,:fill_opacity,:fill_rule,:stroke,:stroke_dasharray,:stroke_dashoffset,:stroke_linecap,:stroke_linejoin,:stroke_miterlimit,:stroke_opacity,:stroke_width]
    VALID_VALUES = {
      :fill_rule => ['nonzero','evenodd'],
      :stroke_linecap => ['butt','round','square'],
      :stroke_linejoin => ['miter','round','bevel']
    }

    ##
    # :method: fill

    ##
    # :method: fill_opacity

    ##
    # :method: fill_rule

    ##
    # :method: stroke

    ##
    # :method: stroke_dasharray

    ##
    # :method: stroke_dashoffset

    ##
    # :method: stroke_linecap

    ##
    # :method: stroke_linejoin

    ##
    # :method: stroke_miterlimit

    ##
    # :method: stroke_opacity

    ##
    # :method: stroke_width

    ##
    attr_reader *IMPLEMENT_ATTRIBUTES

    def initialize(options={})
      case options
      when Painting
        IMPLEMENT_ATTRIBUTES.each do |attr|
          instance_variable_set("@#{attr}", options.__send__(attr))
        end
      when Hash
        options.each do |attr, value|
          __send__("#{attr}=", value) if IMPLEMENT_ATTRIBUTES.include?(attr.to_sym)
        end
      else
        raise TypeError, "#{options.class} can't be coerced into #{self.class}"
      end
    end

    ##
    # :method: fill_rule=
    # 
    # :call-seq:
    # fill_rule= (value)
    # 

    ##
    # :method: stroke_linecap=
    # 
    # :call-seq:
    # stroke_linecap= (value)
    # 

    ##
    # :method: stroke_linejoin=
    # 
    # :call-seq:
    # stroke_linejoin= (value)
    # 

    ##
    VALID_VALUES.each do |attr, valid_values|
      define_method("#{attr.to_s}=") {|value|
        if (value = value.to_s).size == 0
          instance_variable_set("@#{attr}", nil)
        else
          raise ArgumentError, "`#{value}' is invalid #{attr}" unless VALID_VALUES[attr].include?(value)
          instance_variable_set("@#{attr}", value)
        end
      }
    end

    def fill=(color)
      @fill = color.respond_to?(:color?) && color.color? ? color : Color.new_or_nil(color)
    end

    def stroke=(color)
      @stroke = color.respond_to?(:color?) && color.color? ? color : Color.new_or_nil(color)
    end

    def fill_opacity=(opacity)
      @fill_opacity = opacity.nil? ? nil : opacity.to_f
    end

    def stroke_opacity=(opacity)
      @stroke_opacity = opacity.nil? ? nil : opacity.to_f
    end

    def stroke_width=(width)
      @stroke_width = Length.new_or_nil(width)
    end

    def stroke_miterlimit=(miterlimit)
      @stroke_miterlimit = miterlimit.nil? ? nil : [miterlimit.to_f, 1].max
    end

    def stroke_dasharray=(array)
      if (array.nil? || array.empty?)
        @stroke_dasharray = nil
      elsif array.kind_of?(String)
        @stroke_dasharray = array.split(/\s*,\s*/).map {|len| Length.new(len)}
      else
        @stroke_dasharray = array.map {|len| Length.new(len)}
      end
    end

    def stroke_dashoffset=(offset)
      @stroke_dashoffset = Length.new_or_nil(offset)
    end

    def attributes
      IMPLEMENT_ATTRIBUTES.inject({}) do |hash, attr|
        value = instance_variable_get("@#{attr}")
        unless value.nil?
          hash[attr] = value # value.respond_to?(:join) ? value.join(',') : value.to_s
        end
        hash
      end
    end

    def empty?
      IMPLEMENT_ATTRIBUTES.all? do |attr|
        not instance_variable_get("@#{attr}")
      end
    end

    class << self

      def new_or_nil(*args)
        (args.size == 1 && args.first.nil?) ? nil : new(*args)
      end
    end
  end
end
