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
# This file provides the classes of client side scripting.  The script becomes
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
          parts << 'document.getElementById("' << (element.respond_to?(:publish_id) ? element.id : element) << '")'
          parts.join
        end

        def add_event_listener(event, listener)
          parts = []
          parts << get_element(event.target)
          parts << '.addEventListener("' << event.event_name
          parts << '", function(' << listener.arguments.join(', ') << ") {\n"
          parts << listener.body
          parts << '})'
          parts.join
        end

        def dispatch_evnet(event)
          parts = []
          parts << get_element(event.target)
          parts << '.dispatchEvent("' << event.event_name << '")'
          parts.join
        end

        def draw_text_border(*elements)
          parts = []
          parts << "  (function(){\n"
          parts << "    var elms = ["
          script_elements =
              elements.map do |element|
                el_parts = []
                el_parts << '{el:'
                el_parts << get_element(element)
                el_parts << ',hp:'
                el_parts << (element.attributes[:horizontal_padding] || 
                             element.attributes[:padding] || 0)
                el_parts << ',vp:'
                el_parts << (element.attributes[:vertical_padding] ||
                             element.attributes[:padding] || 0)
                el_parts << '}'
                el_parts.join
              end
          parts << script_elements.join(",\n                ")
          parts << "];\n"
          parts << "    for(var i=0; i<#{elements.size}; i++){\n"
          parts << "      var elm = elms[i];\n"
          parts << "      var top=null,right=null,bottom=null,left=null,rect=null;\n"
          parts << "      for(var j=0, len=elm.el.childNodes.length; j<len; j++){\n"
          parts << "        var node = elm.el.childNodes.item(j);\n"
          parts << "        if(node.nodeName == \"text\") {\n"
          parts << "          var text_width = node.getComputedTextLength();\n"
          parts << "          var ext = node.getExtentOfChar(0);\n"
          parts << "          if(top == null || ext.y < top)\n"
          parts << "            top = ext.y;\n"
          parts << "          if(right == null || right < ext.x + text_width)\n"
          parts << "            right = ext.x + text_width;\n"
          parts << "          if(bottom == null || bottom < ext.y + ext.height)\n"
          parts << "            bottom = ext.y + ext.height;\n"
          parts << "          if(left == null || ext.x < left)\n"
          parts << "            left = ext.x;\n"
          parts << "        }\n"
          parts << "        else if(node.nodeName == \"rect\")\n"
          parts << "          rect = node;\n"
          parts << "      }\n"
          parts << "      rect.setAttribute(\"x\", left - elm.hp);\n"
          parts << "      rect.setAttribute(\"y\", top - elm.vp);\n"
          parts << "      rect.setAttribute(\"width\", right - left + elm.hp * 2);\n"
          parts << "      rect.setAttribute(\"height\", bottom - top + elm.vp * 2);\n"
          parts << "    }\n"
          parts << "  })();\n"
          parts.join
        end

        def form_legend_labels(legend)
          parts = []
          parts << "  (function(){\n"
          parts << "    var legend = #{get_element(legend)}\n"
          parts << "    var lengths = [];\n"
          parts << "    var groups = legend.childNodes;\n"
          parts << "    for(var i=0,lenI=groups.length; i<lenI; i++){\n"
          parts << "      if(groups.item(i).nodeName == \"g\"){\n"
          parts << "        var lens = [];\n"
          parts << "        var texts = groups.item(i).childNodes;\n"
          parts << "        for(var j=0,lenJ=texts.length; j<lenJ; j++){\n"
          parts << "          if(texts.item(j).nodeName == \"text\"){\n"
          parts << "            lens.push(texts.item(j).getComputedTextLength());\n"
          parts << "          }\n"
          parts << "        }\n"
          parts << "        lengths.push(lens);\n"
          parts << "      }\n"
          parts << "    }\n"
          parts << "    var max_lengths = [];\n"
          parts << "    lengths.forEach(function(lens, i, lengths){\n"
          parts << "      if(i == 0){\n"
          parts << "        max_lengths = lens;\n"
          parts << "        return;\n"
          parts << "      }\n"
          parts << "      for(j=0; j<max_lengths.length; j++){\n"
          parts << "        if(max_lengths[j] < lens[j])\n"
          parts << "          max_lengths[j] = lens[j];\n"
          parts << "      }\n"
          parts << "    });\n"
          parts << "    for(i=0; i<lenI; i++){\n"
          parts << "      if(groups.item(i).nodeName == \"g\"){\n"
          parts << "        var lens = [];\n"
          parts << "        var texts = groups.item(i).childNodes;\n"
          parts << "        var k = 0, x = 0;\n"
          parts << "        for(j=0,lenJ=texts.length; j<lenJ; j++){\n"
          parts << "          var node = texts.item(j);\n"
          parts << "          if(node.nodeName == \"rect\"){\n"
          parts << "            x = Number(node.getAttribute(\"x\")) + Number(node.getAttribute(\"width\"));\n"
          parts << "          }\n"
          parts << "          else if(node.nodeName == \"line\"){\n"
          parts << "            x = Number(node.getAttribute(\"x2\"));\n"
          parts << "          }\n"
          parts << "          else if(node.nodeName == \"text\"){\n"
          parts << "            x += node.getExtentOfChar(0).height * 0.5;\n"
          parts << "            if(node.getAttribute(\"text-anchor\") == \"middle\"){\n"
          parts << "              x += max_lengths[k] / 2.0;\n"
          parts << "              node.setAttribute(\"x\", x);\n"
          parts << "              x += max_lengths[k] / 2.0;\n"
          parts << "            }\n"
          parts << "            else if(node.getAttribute(\"text-anchor\") == \"end\"){\n"
          parts << "              x += max_lengths[k];\n"
          parts << "              node.setAttribute(\"x\", x);\n"
          parts << "            }\n"
          parts << "            else {\n"
          parts << "              node.setAttribute(\"x\", x);\n"
          parts << "              x += max_lengths[k];\n"
          parts << "            }\n"
          parts << "            k++;\n"
          parts << "          }\n"
          parts << "        }\n"
          parts << "        lengths.push(lens);\n"
          parts << "      }\n"
          parts << "    }\n"
          parts << "  })();\n"
          parts.join
        end
      end

      # Class representing a function of ECMAScript.  The scripting becomes
      # effective only when it is output by SVG format.
      class Function < SimpleScript
        attr_reader :name, :arguments

        # @param [String] body body of client scripting
        # @param [String] name a function name
        # @param [Array] arguments a list of argument's name
        def initialize(body, name=nil, *arguments)
          super(body)
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

        # (see SimpleScript#body)
        def body
          parts = []
          parts << 'function'
          parts << " #{name}" if name
          parts << '('
          parts << arguments.join(', ')
          parts << ") {\n"
          parts << @body
          parts << "}\n"
          parts.join
        end
      end

      # Class representing a event listener of ECMAScript.  The scripting
      # becomes effective only when it is output by SVG format.
      class EventListener < Function

        # @param [String] body body of client scripting
        # @param [String] name a function name
        # @param [String] argument argument's name
        def initialize(body, name=nil, argument='evt')
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

        # (see SimpleScript#body)
        def body
          if name
            super
          else
            parts = []
            parts << "setTimeout(function() {\n"
            @events.each do |event|
              if event.event_name == :load
                parts << @body
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
                parts << @body
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