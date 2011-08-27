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
#
# == Overview
#
# This file provides the classes of client side scripting.  The event becomes
# effective only when it is output by SVG format.
#
# @since 1.0.0

module DYI
  module Script

    # Class representing a inline-client-script.  The scripting becomes
    # effective only when it is output by SVG format.
    class InlineScript

      # @return [String] content-type of script
      attr_reader :content_type
      # @return [String] substance of client scripting
      attr_reader :substance

      # @param [String] substance substance of client scripting
      # @param [String] content_type content-type of script
      def initialize(substance, content_type = 'application/ecmascript')
        @content_type = content_type
        @substance = substance
      end

      # Returns this script includes reference of external script file.
      # @return [Boolean] always returns false
      def has_uri_reference?
        false
      end

      # Writes the buffer contents of the object.
      # @param [Formatter::Base] a formatter for export
      # @param [IO] io a buffer that is written
      # @return [void]
      def write_as(formatter, io=$>)
        formatter.write_inline_script(self, io)
      end
    end

    # Class representing a referenct of external client-script-file.
    # The scripting becomes effective only when it is output by SVG format.
    class ExternalScript

      # @return [String] content-type of script
      attr_reader :content_type
      # @return [String] a path of external script file
      attr_reader :href

      def initialize(href, content_type = 'application/ecmascript')
        @content_type = content_type
        @href = href
      end

      # Returns whether this script contains reference of external script file.
      # @return [Boolean] always returns true
      def has_uri_reference?
        true
      end

      # (see InlineScript#write_as)
      def write_as(formatter, io=$>)
        formatter.write_external_script(self, io)
      end
    end
  end
end