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
module DYI
  module Script

    # Module for using ECMAScript.  The script generated by this module comfirms
    # to ECMAScript 5.1 (Ecma International Standard ECMA-262).
    # @since 1.0.0
    module EcmaScript

      # This Module includes helper methods for generating a client-script.
      # These methods generate a script that conforms to DOM Level 2 (W3C
      # Recommendation).
      #
      # All the methods defined by the module are 'module functions', which are
      # called as private instance methods and are also called as public class
      # methods (they are methods of Math Module like).
      # In the following example, +get_element+ method is called as a
      # private instance method.
      #   class Foo
      #     include DYI::Script::EcmaScript::DomLevel2
      #     def bar
      #       puts get_element('el_id') # => "document.getElementById(\"el_id\")"
      #     end
      #   end
      # At the toplevel, it is able to include the module.
      #   include DYI::Script::EcmaScript::DomLevel2
      #   puts get_element('el_id')     # => "document.getElementById(\"el_id\")"
      # In the next example, +get_element+ method is called as a public class
      # method.
      #   puts DYI::Script::EcmaScript::DomLevel2.get_element('el_id')
      #                                 # => "document.getElementById(\"el_id\")"
      module DomLevel2

        private

        # @function
        def get_element(element)
          parts = []
          parts << 'document.getElementById("' << (element.respond_to?(:publish_id) ? element.id : element) << '")'
          parts.join
        end

        # @function
        def add_event_listener(event, listener)
          parts = []
          parts << get_element(event.target)
          parts << '.addEventListener("' << event.event_name
          parts << '", function(' << listener.arguments.join(', ') << ") {\n"
          parts << listener.body
          parts << '}, false)'
          parts.join
        end

        # @function
        def dispatch_evnet(event)
          parts = []
          parts << get_element(event.target)
          parts << '.dispatchEvent("' << event.event_name << '")'
          parts.join
        end

        # Returns an ECMAScript value of a metadata that this image has.
        # @return [String] a string that means 
        # @function
        # @since 1.1.1
        def metadata_parse_json
=begin
script =<<-EOS
(function() {
  var metadata_element = document.getElementsByTagName("metadata").item(0);
  if(metadata_element == null)
    return null;
  var metadata_contents = [];
  for(var i=0, length=metadata_element.childNodes.length; i<length; i++) {
    var child = metadata_element.childNodes.item(i);
    if(child.nodeType!=3&&child.nodeType!=4)
      return null;
    metadata_contents.push(child.data);
  }
  if(metadata_contents.length == 0)
    return null;
  return JSON.parse(metadata_contents.join(""));
})()
EOS
=end
          '(function(){var a=document.getElementsByTagName("metadata").item(0);if(a==null)return null;var b=[];for(var c=0,d=a.childNodes.length;c<d;c++){var e=a.childNodes.item(c);if(e.nodeType!=3&&e.nodeType!=4)return null;b.push(e.data);}if(b.length==0)return null;return JSON.parse(b.join(""));})()'
        end

        # Returns an ECMAScript value of attribute of the element.
        # @param [Element|String] element the target element or id of the target
        # element
        # @param [String|Symbol] attribute_name the name of attribute
        # @return [String] ECMAScript string
        # @function
        # @example
        #   rect = pen.draw_rectange(canvas, [0, 0], 20, 30, :id => "rect1")
        #   get_attribute(rect, "width")
        #        # => "document.getElementById(\"rect1\").getAttribute(\"width\")"
        # @function
        # @since 1.1.0
        def get_attribute(element, attribute_name)
          "#{get_element(element)}.getAttribute(\"#{attribute_name}\")"
        end

        # Returns an ECMAScript expression that sets a value to the element.
        # @param [Element|String] element the target element or id of the target
        # element
        # @param [String|Symbol] attribute_name the name of attribute
        # @param [Object] value a value of attribute, calls a to_s method
        # @return [String] ECMAScript string
        # @example
        #   rect = pen.draw_rectange(canvas, [0, 0], 20, 30, :id => "rect1")
        #   set_attribute(rect, "width", 50)
        #        # => "document.getElementById(\"rect1\").setAttribute(\"x\",\"50\")"
        # @function
        # @since 1.1.0
        def set_attribute(element, attribute_name, value)
          "#{get_element(element)}.setAttribute(\"#{attribute_name}\",\"#{value.to_s}\")"
        end

        # Returns an ECMAScript expression that rewrite text node of a <text>
        # element.
        # @param [Shape::Text] text_element the target element
        # @param [String] text new contents of the text element
        # @return [String] ECMAScript string
        # @function
        # @since 1.1.0
        def rewrite_text(text_element, text)
          lines = text.split(/(?:\r\n|\n|\r)/).map{|line| to_ecmascript_string(line)}
=begin
script =<<-EOS
(function() {
  var texts = [\#{lines.join(",")}];
  var text_elements = \#{get_element(text_element)}.getElementsByTagName("text");
  for (var i=0,len=text_elements.length; i<len; i++){
    if(texts.length <= i)
      break;
    text_elements[i].replaceChild(document.createTextNode(texts[i]), text_elements[i].lastChild);
  }
})();
EOS
=end
          "(function(){var a=[#{lines.join(",")}];var b=#{get_element(text_element)}.getElementsByTagName(\"text\");for(var c=0,len=b.length;c<len;c++){if(a.length<=c)break;b[c].replaceChild(document.createTextNode(a[c]),b[c].lastChild);}})();"
        end

        # Returns an ECMAScript string literal that mean any Ruby object.
        # This method calls to_s method to convert into string.
        # @param [Object] obj any Ruby object
        # @return [String] ECMAScript string
        # @example
        #   to_ecmascript_string("abc") #=> "\"abc\""
        #   to_ecmascript_string('This figure is made using "DYI".')
        #       #=> "\"This figure is made using \\\"DYI\\\".\""
        #   to_ecmascript_string("\346\227\245\346\234\254\350\252\236")
        #       #=> "\"\\u65E5\\u672C\\u8A9E\""  (encoding: utf-8)
        # @function
        # @since 1.1.0
        def to_ecmascript_string(obj)
          chars = []
          chars << '"'
          obj.to_s.unpack('U*').each do |c|
            case c
              when 0x08 then chars << '\\b'
              when 0x09 then chars << '\\t'
              when 0x0a then chars << '\\n'
              when 0x0b then chars << '\\v'
              when 0x0c then chars << '\\f'
              when 0x0d then chars << '\\r'
              when 0x22 then chars << '\\"'
              when 0x5c then chars << '\\\\'
              when (0x20..0x7e) then chars << c.chr
              else chars << '\\u' << ('%04X' % c)
            end
          end
          chars << '"'
          chars.join
        end

        # @function
        def draw_text_border(*elements)
          elements_js_variable = []
          elements_js_variable << "var a=["
          script_elements =
              elements.map do |element|
                el_parts = []
                el_parts << '{a:'
                el_parts << get_element(element)
                el_parts << ',b:'
                el_parts << (element.attributes[:horizontal_padding] || 
                             element.attributes[:padding] || 0)
                el_parts << ',c:'
                el_parts << (element.attributes[:vertical_padding] ||
                             element.attributes[:padding] || 0)
                el_parts << '}'
                el_parts.join
              end
          elements_js_variable << script_elements.join(",") << "];"
=begin
script =<<-EOS
(function(){
  \#{elements_js_variable.join}
  for(var i=0; i<\#{elements.size}; i++){
    var elm = a[i];
    var top=null,right=null,bottom=null,left=null,rect=null;
    for(var j=0, len=elm.a.childNodes.length; j<len; j++){
      var node = elm.a.childNodes.item(j);
      if(node.localName == \"text\") {
        var text_width = node.getComputedTextLength();
        if(node.getNumberOfChars() > 0){
          var ext = node.getExtentOfChar(0);
          if(top == null || ext.y < top)
            top = ext.y;
          if(right == null || right < ext.x + text_width)
            right = ext.x + text_width;
          if(bottom == null || bottom < ext.y + ext.height)
            bottom = ext.y + ext.height;
          if(left == null || ext.x < left)
            left = ext.x;
        }
      }
      else if(node.localName == \"rect\")
        rect = node;
    }
    rect.setAttribute(\"x\", left - elm.b);
    rect.setAttribute(\"y\", top - elm.c);
    rect.setAttribute(\"width\", right - left + elm.b * 2);
    rect.setAttribute(\"height\", bottom - top + elm.c * 2);
  }
})();
EOS
=end
          "(function(){#{elements_js_variable.join}for(var b=0;b<#{elements.size};b++){var c=a[b];var d=null,right=null,bottom=null,left=null,rect=null;for(var e=0,len=c.a.childNodes.length;e<len;e++){var f=c.a.childNodes.item(e);if(f.localName==\"text\"){var g=f.getComputedTextLength();if(f.getNumberOfChars()>0){var h=f.getExtentOfChar(0);if(d==null||h.y<d)d=h.y;if(right==null||right<h.x+g)right=h.x+g;if(bottom==null||bottom<h.y+h.height)bottom=h.y+h.height;if(left==null||h.x<left)left=h.x;}}else if(f.localName==\"rect\")rect=f;}rect.setAttribute(\"x\",left-c.b);rect.setAttribute(\"y\",d-c.c);rect.setAttribute(\"width\",right-left+c.b*2);rect.setAttribute(\"height\",bottom-d+c.c*2);}})();"
        end

        # @function
        def form_legend_labels(legend)
=begin
script =<<-EOS
(function(){
  var legend = \#{get_element(legend)};
  var lengths = [];
  var groups = legend.childNodes;
  for(var i=0,lenI=groups.length; i<lenI; i++){
    if(groups.item(i).localName == \"g\"){
      var lens = [];
      var texts = groups.item(i).childNodes;
      for(var j=0,lenJ=texts.length; j<lenJ; j++){
        if(texts.item(j).localName == \"text\"){
          lens.push(texts.item(j).getComputedTextLength());
        }
      }
      lengths.push(lens);
    }
  }
  var max_lengths = [];
  lengths.forEach(function(lens, i, lengths){
    if(i == 0){
      max_lengths = lens;
      return;
    }
    for(j=0; j<max_lengths.length; j++){
      if(max_lengths[j] < lens[j])
        max_lengths[j] = lens[j];
    }
  });
  for(i=0; i<lenI; i++){
    if(groups.item(i).localName == \"g\"){
      var lens = [];
      var texts = groups.item(i).childNodes;
      var k = 0, x = 0;
      for(j=0,lenJ=texts.length; j<lenJ; j++){
        var node = texts.item(j);
        if(node.localName == \"rect\"){
          x = Number(node.getAttribute(\"x\")) + Number(node.getAttribute(\"width\"));
        }
        else if(node.localName == \"line\"){
          x = Number(node.getAttribute(\"x2\"));
        }
        else if(node.localName == \"text\"){
          x += node.getExtentOfChar(0).height * 0.5;
          if(node.getAttribute(\"text-anchor\") == \"middle\"){
            x += max_lengths[k] / 2.0;
            node.setAttribute(\"x\", x);
            x += max_lengths[k] / 2.0;
          }
          else if(node.getAttribute(\"text-anchor\") == \"end\"){
            x += max_lengths[k];
            node.setAttribute(\"x\", x);
          }
          else {
            node.setAttribute(\"x\", x);
            x += max_lengths[k];
          }
          k++;
        }
      }
      lengths.push(lens);
    }
  }
})();
EOS
=end
          "(function(){var a=#{get_element(legend)};var b=[];var c=a.childNodes;for(var d=0,e=c.length;d<e;d++){if(c.item(d).localName==\"g\"){var f=[];var g=c.item(d).childNodes;for(var h=0,i=g.length;h<i;h++){if(g.item(h).localName==\"text\"){f.push(g.item(h).getComputedTextLength());}}b.push(f);}}var j=[];b.forEach(function(f,d,b){if(d==0){j=f;return;}for(h=0;h<j.length;h++){if(j[h]<f[h])j[h]=f[h];}});for(d=0;d<e;d++){if(c.item(d).localName==\"g\"){var f=[];var g=c.item(d).childNodes;var k=0,l=0;for(h=0,i=g.length;h<i;h++){var m=g.item(h);if(m.localName==\"rect\"){l=Number(m.getAttribute(\"x\"))+Number(m.getAttribute(\"width\"));}else if(m.localName==\"line\"){l=Number(m.getAttribute(\"x2\"));}else if(m.localName==\"text\"){l+=m.getExtentOfChar(0).height*0.5;if(m.getAttribute(\"text-anchor\")==\"middle\"){l+=j[k]/2.0;m.setAttribute(\"x\",l);l+=j[k]/2.0;}else if(m.getAttribute(\"text-anchor\")==\"end\"){l+=j[k];m.setAttribute(\"x\",l);}else{m.setAttribute(\"x\",l);l+=j[k];}k++;}}b.push(f);}}})();"
        end

        module_function(*private_instance_methods)
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

        # @since 1.0.3
        def contents
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
        def related_to(event)
          unless @events.include?(event)
            @events << event
          end
        end

        # Removes the relation to an event.
        # @param [Event] event an event that is removed the relation to
        def unrelated_to(event)
          @events.delete(event)
        end

        # @since 1.0.3
        def contents
          if name
            super
          else
            parts = []
            parts << "addEventListener(\"load\", function(evt) {\n"
            @events.each do |event|
              if event.event_name == :load
                parts << @body
              elsif
                if event.target.root_element?
                  parts << '  document.documentElement.addEventListener("'
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
            parts << "}, false);\n"
            parts.join
          end
        end
      end
    end
  end
end