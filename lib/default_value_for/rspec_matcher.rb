require "default_value_for"

RSpec::Matchers.define :set_default_value_for do |attribute|
  match do
    @attribute = attribute
    actual_class_name = subject.is_a?(Class) ? subject : subject.class
    @default_values = actual_class_name._default_attribute_values
    @disallowed_nils = actual_class_name._default_attribute_values_not_allowing_nil
    sets_value? && sets_given_value? && disallows_nil?
  end

  chain :with_value do |value|
    @expected_value = value
  end

  chain :and_disallow_nil do
    @expected_disallowed_nil = true
  end

  description do
    message = "set default value for '#{attribute}'"
    message += " with value '#{@expected_value}'" if @expected_value
    message += " and disallows_nil" if @expected_disallowed_nil
    message
  end

  failure_message_for_should do
    "expected to #{description}"
  end

  failure_message_for_should_not do
    "expected to not #{description}"
  end

  # TO DO : Support block comapre. Watch out for Time.now == Time.now (it returns false)

  #chain :with_block &block;end

  private

  def sets_value?
    !expect(@default_values[@attribute.to_s]).not_to be_nil
  end

  def sets_given_value?
    @expected_value ? expect(@default_values[@attribute.to_s].instance_variable_get('@value')).to(eq(@expected_value)) : true
  end

  def disallows_nil?
    @expected_disallowed_nil ? @disallowed_nils.include?(@attribute) : true
  end
end
