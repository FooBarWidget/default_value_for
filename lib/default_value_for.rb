# Copyright (c) 2008-2012 Phusion
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

module DefaultValueFor
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
      if @block.arity == 0
        return @block.call
      else
        return @block.call(instance)
      end
    end
  end

  module ClassMethods
    # Declares a default value for the given attribute.
    #
    # Sets the default value to the given options parameter unless the given options equal { :value => ... }
    #
    # The <tt>options</tt> can be used to specify the following things:
    # * <tt>value</tt> - Sets the default value.
    # * <tt>allows_nil (default: true)</tt> - Sets explicitly passed nil values if option is set to true.
    def default_value_for(attribute, options = {}, &block)
      value      = options
      allows_nil = true

      if options.is_a?(Hash)
        opts       = options.stringify_keys
        value      = opts.fetch('value', options)
        allows_nil = opts.fetch('allows_nil', true)
      end

      if !method_defined?(:set_default_values)
        include(InstanceMethods)

        after_initialize :set_default_values

        class_attribute :_default_attribute_values
        class_attribute :_default_attribute_values_not_allowing_nil

        extend(DelayedClassMethods)
        init_hash = true
      else
        init_hash = !singleton_methods(false).include?(:_default_attribute_values)
      end

      if init_hash
        self._default_attribute_values = {}
        self._default_attribute_values_not_allowing_nil = []
      end

      if block_given?
        container = BlockValueContainer.new(block)
      else
        container = NormalValueContainer.new(value)
      end
      _default_attribute_values[attribute.to_s] = container
      _default_attribute_values_not_allowing_nil << attribute.to_s unless allows_nil
    end

    def default_values(values)
      values.each_pair do |key, options|
        options = options.stringify_keys if options.is_a?(Hash)

        value = options.is_a?(Hash) && options.has_key?('value') ? options['value'] : options

        if value.kind_of? Proc
          default_value_for(key, options.is_a?(Hash) ? options : {}, &value)
        else
          default_value_for(key, options)
        end
      end
    end
  end

  module DelayedClassMethods
    def _all_default_attribute_values
      return _default_attribute_values unless superclass.respond_to?(:_default_attribute_values)
      superclass._all_default_attribute_values.merge(_default_attribute_values)
    end

    def _all_default_attribute_values_not_allowing_nil
      return _default_attribute_values_not_allowing_nil unless superclass.respond_to?(:_default_attribute_values_not_allowing_nil)
      result = superclass._all_default_attribute_values_not_allowing_nil + _default_attribute_values_not_allowing_nil
      result.uniq!
      result
    end
  end

  module InstanceMethods
    def initialize(attributes = nil, options = {})
      attributes = attributes.to_h if attributes.respond_to?(:to_h)
      @initialization_attributes = attributes.is_a?(Hash) ? attributes.stringify_keys : {}

      unless options[:without_protection]
        if respond_to?(:mass_assignment_options, true) && options.has_key?(:as)
          @initialization_attributes = sanitize_for_mass_assignment(@initialization_attributes, options[:as])
        elsif respond_to?(:sanitize_for_mass_assignment, true)
          @initialization_attributes = sanitize_for_mass_assignment(@initialization_attributes)
        else
          @initialization_attributes = remove_attributes_protected_from_mass_assignment(@initialization_attributes)
        end
      end

      if self.class.respond_to? :protected_attributes
        super(attributes.merge(options))
      else
        super(attributes)
      end
    end

    def attributes_for_create(attribute_names)
      attribute_names += self.class._all_default_attribute_values.keys.map(&:to_s).find_all { |name|
        self.class.columns_hash.key?(name)
      }
      super
    end

    def set_default_values
      self.class._all_default_attribute_values.each do |attribute, container|
        next unless new_record? || self.class._all_default_attribute_values_not_allowing_nil.include?(attribute)

        connection_default_value_defined = new_record? && respond_to?("#{attribute}_changed?") && !__send__("#{attribute}_changed?")

        attribute_blank = if attributes.has_key?(attribute)
                            column = self.class.columns_hash[attribute]
                            if column && column.type == :boolean
                              attributes[attribute].nil?
                            else
                              attributes[attribute].blank?
                            end
                          elsif respond_to?(attribute)
                            send(attribute).nil?
                          else
                            instance_variable_get("@#{attribute}").nil?
                          end
        next unless connection_default_value_defined || attribute_blank

        # allow explicitly setting nil through allow nil option
        next if @initialization_attributes.is_a?(Hash) &&
                (
                  @initialization_attributes.has_key?(attribute) ||
                  (
                    @initialization_attributes.has_key?("#{attribute}_attributes") &&
                    nested_attributes_options.stringify_keys[attribute]
                  )
                ) &&
                !self.class._all_default_attribute_values_not_allowing_nil.include?(attribute)

        __send__("#{attribute}=", container.evaluate(self))
        if respond_to?(:clear_attribute_changes, true)
          clear_attribute_changes [attribute] if has_attribute?(attribute)
        else
          changed_attributes.delete(attribute)
        end
      end
    end
  end
end

if defined?(Rails::Railtie)
  require 'default_value_for/railtie'
else
  # For anybody is using AS and AR without Railties, i.e. Padrino.
  ActiveRecord::Base.extend(DefaultValueFor::ClassMethods)
end
