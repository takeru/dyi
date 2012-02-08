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

# Root namespace of DYI.
# @since 0.0.0
module DYI

  # DYI program version
  VERSION = '1.1.2'

  # URL of DYI Project
  # @since 0.0.2
  URL = 'http://sourceforge.net/projects/dyi/'
end

%w(

util
dyi/util
dyi/length
dyi/coordinate
dyi/color
dyi/painting
dyi/font
dyi/matrix
dyi/type
dyi/svg_element
dyi/element
dyi/canvas
dyi/shape
dyi/drawing
dyi/event
dyi/animation
dyi/script
dyi/stylesheet
dyi/formatter
dyi/chart

).each do |file_name|
  require File.join(File.dirname(__FILE__), file_name)
end

if defined? IRONRUBY_VERSION
  require File.join(File.dirname(__FILE__), 'ironruby')
end
