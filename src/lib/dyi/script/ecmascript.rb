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
    # Module for using ECMAScript.
    module EcmaScript

      # This Module includes helper methods for generating a client-script.
      # These methods generate a script that conforms to DOM Level 2 (W3C
      # Recommendation).
      module DomLevel2
        def get_element(element)
          parts = []
          parts << 'getElementById("' << element.id << '")'
          parts.join
        end
        def add_event_listener(event, listener)
          parts = []
          parts << get_element(event.target)
          parts << '.addEventListener("' << event.event_name
          parts << '", function(' << listener.arguments.join(', ') << ") {\n"
          parts << listener.substance
          parts << '})'
          parts.join
        end
        def dispatch_evnet(event)
          parts = []
          parts << get_element(event.target)
          parts << '.dispatchEvent("' << event.event_name << '")'
          parts.join
        end
        def children_each(element, script, arg_name='elem', tag_name=nil)
        end
        def elements_each(element, script, arg_name='elem')
        end
      end

      # Class representing a function of ECMAScript.  The scripting becomes
      # effective only when it is output by SVG format.
      class Function < InlineScript
        attr_reader :name, :arguments

        # @param [String] substance substance of client scripting
        # @param [String] name a function name
        # @param [Array] arguments a list of argument's name
        def initialize(substance, name=nil, *arguments)
          super(substance)
          if name && name !~ /\A[\$A-Z_a-z][\$0-9A-Z_a-z]*\z/
            raise ArgumentError, "illegal identifier: `#{name}'"
          end
          @name = name
          @arguments = arguments.map do |arg|
            if arg.to_s !~ /\A[\$A-Z_a-z][\$0-9A-Z_a-z]*\z/
              raise ArgumentError, "illegal identifier: `#{arg}'"
            end
            arg.to_s
          end
        end

        # (see InlineScript#substance)
        def substance
          parts = []
          parts << 'function'
          parts << " #{name}" if name
          parts << '('
          parts << arguments.join(', ')
          parts << ") {\n"
          parts << @substance
          parts << "}\n"
          parts.join
        end
      end

      # Class representing a event listener of ECMAScript.  The scripting
      # becomes effective only when it is output by SVG format.
      class EventListener < Function

        # @param [String] substance substance of client scripting
        # @param [String] name a function name
        # @param [String] argument argument's name
        def initialize(substance, name=nil, argument='evt')
          super
          @events = []
        end

        # Relates this object to an event.
        # @param [Event] event an event that is related to
        # @return [void]
        def related_to(event)
          @events << event
        end

        # Removes the relation to an event.
        # @param [Event] event an event that is removed the relation to
        # @return [void]
        def unrelated_to(event)
          @events.delete(event)
        end

        # (see InlineScript#substance)
        def substance
          if name
            super
          else
            parts = []
            parts << "setTimeout(function() {\n"
            @events.each do |event|
              if event.event_name == :load
                parts << @substance
              elsif
                if event.target.root_element?
                  parts << '  document.rootElement.addEventListener("'
                else
                  parts << '  document.getElementById("'
                  parts << event.target.id
                  parts << '").addEventListener("'
                end
                parts << event.event_name
                parts << '", function('
                parts << arguments.join(', ')
                parts << ") {\n"
                parts << @substance
                parts << "  }, false);\n"
              end
            end
            parts << "}, 0);\n"
            parts.join
          end
        end
      end
    end
  end
end