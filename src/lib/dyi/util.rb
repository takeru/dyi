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

module DYI

  # @since 1.1.0
  module Util

    private

    def to_radian(degree)
      Math::PI * degree / 180
    end

    def sin(degree)
      Math.sin(to_radian(degree))
    end

    def cos(degree)
      Math.cos(to_radian(degree))
    end

    def tan(degree)
      Math.tan(to_radian(degree))
    end

    def asin(x)
      Math.asin(x) * 180 / Math::PI
    end

    def acos(x)
      Math.acos(x) * 180 / Math::PI
    end

    def atan(x)
      Math.atan(x) * 180 / Math::PI
    end

    module_function(*private_instance_methods)
  end
end
