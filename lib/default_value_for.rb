require "default_value_for/railtie"

module DefaultValueForPlugin
	class NormalValueContainer
		def initialize(value)
			@value = value
		end

		def evaluate(instance)
			if @value.duplicable?
				return @value.dup
			else
				return @value
			end
		end
	end

	class BlockValueContainer
		def initialize(block)
			@block = block
		end

		def evaluate(instance)
			return @block.call(instance)
		end
	end

	module ClassMethods
		def default_value_for(attribute, value = nil, &block)
			if !method_defined?(:initialize_with_defaults)
				include(InstanceMethods)
				alias_method_chain :initialize, :defaults
				class_inheritable_accessor :_default_attribute_values
				self._default_attribute_values = ActiveSupport::OrderedHash.new
			end
			if block_given?
				container = BlockValueContainer.new(block)
			else
				container = NormalValueContainer.new(value)
			end
			_default_attribute_values[attribute.to_s] = container
		end

		def default_values(values)
			values.each_pair do |key, value|
				if value.kind_of? Proc
					default_value_for(key, &value)
				else
					default_value_for(key, value)
				end
			end
		end
	end

	module InstanceMethods
		def initialize_with_defaults(attrs = nil)
			initialize_without_defaults(attrs) do
				if attrs
					stringified_attrs = attrs.stringify_keys
					safe_attrs = if respond_to? :sanitize_for_mass_assignment
						sanitize_for_mass_assignment(stringified_attrs)
					else
						remove_attributes_protected_from_mass_assignment(stringified_attrs)
					end
					safe_attribute_names = safe_attrs.keys.map do |x|
						x.to_s
					end
				end
				self.class._default_attribute_values.each do |attribute, container|
					if safe_attribute_names.nil? || !safe_attribute_names.any? { |attr_name| attr_name =~ /^#{attribute}($|\()/ }
						__send__("#{attribute}=", container.evaluate(self))
						changed_attributes.delete(attribute)
					end
				end
				yield(self) if block_given?
			end
		end
	end
end
