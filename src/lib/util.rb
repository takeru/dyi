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

class Numeric

  def strfnum(format)
    decimal_separator = (defined? ::Numeric::DECIMAL_SEPARATOR) ? ::Numeric::DECIMAL_SEPARATOR : '.'
    group_separator = (defined? ::Numeric::GROUP_SEPARATOR) ? ::Numeric::GROUP_SEPARATOR : ','
    group_sizes = (defined? ::Numeric::GROUP_SIZES) ? ::Numeric::GROUP_SIZES : 3
    percent_symbol = (defined? ::Numeric::PERCENT_SYMBOL) ? ::Numeric::PERCENT_SYMBOL : '%'

    # lexical analysis
    sec = {:int => [], :dec => [], :int_digit => 0, :dec_digit => 0, :place => 0}
    sections = [sec]
    escaped = false
    forcibly = false
    format.split(//).each do |char|
      if escaped
        if sec[:decimal]
          sec[:dec].push(char)
        else
          sec[:int].push(char)
        end
        escaped = false
        next
      end

      case char
      when '0'
        if sec[:decimal]
          sec[:dec_digit] += 1
          sec[:dec].push(:zero)
        else
          forcibly = true
          sec[:int_digit] += 1
          sec[:int].push(:zero)
          if sec[:place] != 0
            sec[:use_separater] = true
            sec[:place] = 0
          end
        end
      when '#'
        if sec[:decimal]
          sec[:dec_digit] += 1
          sec[:dec].push(:sharp)
        else
          sec[:int_digit] += 1
          sec[:int].push(forcibly ? :zero : :sharp)
          if sec[:place] != 0
            sec[:use_separater] = true
            sec[:place] = 0
          end
        end
      when '.'
        sec[:decimal] = true
      when ','
        sec[:place] += group_sizes unless sec[:decimal]
      when ';'
        forcibly = false
        sec = {:int => [], :dec => [], :int_digit => 0, :dec_digit => 0, :place => 0}
        sections.push(sec)
      when '%'
        sec[:percent] = true
        if sec[:decimal]
          sec[:dec].push(percent_symbol)
        else
          sec[:int].push(percent_symbol)
        end
      when '\\'
        escaped = true
      else
        if sec[:decimal]
          sec[:dec].push(char)
        else
          sec[:int].push(char)
        end
      end
    end

    # choosing of the format (fmt)
    need_minus_sign = false
    case sections.size
    when 1
      need_minus_sign = (self < 0)
      frm = sections[0]
    when 2
      if self >= 0
        frm = sections[0]
      else
        frm = sections[1]
      end
    else
      if self > 0
        frm = sections[0]
      elsif self < 0
        frm = sections[1]
      else
        frm = sections[2]
      end
    end

    value = self

    value *= 100 if frm[:percent]
    value = value.quo(10 ** frm[:place]) if frm[:place] != 0

    int_part, dec_part = ("%.#{frm[:dec_digit]}f" % value.abs).split('.')

    if self.nonzero? && int_part == '0' && !(dec_part =~ /[^0]/)
      if sections[2]
        frm = sections[2]
        value = 0
        int_part, dec_part = ("%.#{frm[:dec_digit]}f" % value.abs).split('.')
      elsif self < 0 && sections[1]
        frm = sections[0]
        value = 0
        int_part, dec_part = ("%.#{frm[:dec_digit]}f" % value.abs).split('.')
      end
    end

    # formatting of integer part
    first = 0
    last = int_part.size - frm[:int_digit]
    int_index = frm[:int_digit]
    last_num = nil
    frm[:int].each_with_index do |place_holder, index|
      case place_holder
      when :zero
        if frm[:use_separater]
          if first == last || last < 0
            num = last < 0 ? '0' : int_part[first, 1]
            if last_num && int_index % group_sizes == 0
              frm[:int][index] = group_separator + num
            elsif last_num.nil? && need_minus_sign
              frm[:int][index] = '-' + num
            else
              frm[:int][index] = num
            end
          else
            num = int_part[first..last]
            i = (int_part.size - 1) % 3 + 1
            while i < num.size
              num.insert(i, group_separator)
              i += 4
            end
            frm[:int][index] = last_num.nil? && need_minus_sign ? '-' + num : num
          end
        else
          num = last < 0 ? '0' : int_part[first..last]
          num = '-' + num if last_num.nil? && need_minus_sign
          frm[:int][index] = num
        end
        first = (last += 1)
        int_index -= 1
        last_num = frm[:int][index]
      when :sharp
        if last < 0
          frm[:int][index] = nil
        elsif frm[:use_separater]
          if first == last
            if last_num && int_index % group_sizes == 0
              frm[:int][index] = group_separator + int_part[first, 1]
            elsif last_num.nil? && need_minus_sign
              frm[:int][index] = '-' + int_part[first, 1]
            else
              frm[:int][index] = int_part[first, 1]
            end
          else
            num = int_part[first..last]
            i = (int_part.size - 1) % 3 + 1
            while i < num.size
              num.insert(i, group_separator)
              i += 4
            end
            frm[:int][index] = last_num.nil? && need_minus_sign ? '-' + num : num
          end
        else
          num = int_part[first..last]
          num = '-' + num if last_num.nil? && need_minus_sign
          frm[:int][index] = num
        end
        first = (last += 1)
        int_index -= 1
        last_num = frm[:int][index]
      end
    end

    # formatting of decimal part
    needs_replaceing = false
    needs_decimal_separator = nil
    dec_index = frm[:dec_digit]
    (frm[:dec].size - 1).downto(0) do |index|
      case frm[:dec][index]
      when :zero
        dec_index -= 1
        frm[:dec][index] = dec_part[dec_index, 1]
        needs_replaceing = true
        needs_decimal_separator = decimal_separator
      when :sharp
        dec_index -= 1
        if needs_replaceing || dec_part[dec_index, 1] != '0'
          frm[:dec][index] = dec_part[dec_index, 1]
          needs_replaceing = true
          needs_decimal_separator = decimal_separator
        else
          frm[:dec][index] = nil
        end
      end
    end

    (frm[:int] + [needs_decimal_separator] + frm[:dec]).join
  end
end