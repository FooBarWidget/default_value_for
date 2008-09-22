# Copyright (c) 2008 Phusion
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

module DefaultValuePlugin
	class NormalValueContainer
		def initialize(value)
			@value = value
		end
	
		def evaluate
			return @value
		end
	end
	
	class BlockValueContainer
		def initialize(model_object, block)
			@model_object = self
			@block = block
		end
	
		def evaluate
			return @block.call(@model_object)
		end
	end
	
	module ClassMethods
		def default_value_for(attribute, value = nil, &block)
			if !method_defined?(:initialize_with_defaults)
				include(InstanceMethods)
				alias_method_chain :initialize, :defaults
				class_inheritable_accessor :_default_attribute_values
				self._default_attribute_values = {}
			end
			if block_given?
				container = BlockValueContainer.new(self, block)
			else
				container = NormalValueContainer.new(value)
			end
			_default_attribute_values[attribute.to_s] = container
		end
	end
	
	module InstanceMethods
		def initialize_with_defaults(attrs = nil)
			initialize_without_defaults(attrs) do
				self.class._default_attribute_values.each_pair do |attribute, container|
					if attrs.nil? || !attrs.keys.map(&:to_s).include?(attribute)
						__send__("#{attribute}=", container.evaluate)
					end
				end
				yield(self) if block_given?
			end
		end
	end
end

ActiveRecord::Base.extend(DefaultValuePlugin::ClassMethods)
