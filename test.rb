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

require 'bundler/setup'
require 'minitest/autorun'
require 'minitest/around/unit'
require 'active_record'

if ActiveSupport::VERSION::MAJOR == 3
  require 'active_support/core_ext/logger'
end

begin
  TestCaseClass = MiniTest::Test
rescue NameError
  TestCaseClass = MiniTest::Unit::TestCase
end

require 'default_value_for'

puts "\nTesting with Active Record version #{ActiveRecord::VERSION::STRING}\n\n"

ActiveRecord::Base.default_timezone = :local
ActiveRecord::Base.logger           = Logger.new(STDERR)
ActiveRecord::Base.logger.level     = Logger::WARN

ActiveRecord::Base.establish_connection(
  :adapter  => RUBY_PLATFORM == 'java' ? 'jdbcsqlite3' : 'sqlite3',
  :database => ':memory:'
)

ActiveRecord::Base.connection.create_table(:users, :force => true) do |t|
  t.string :username
  t.integer :default_number
end

ActiveRecord::Base.connection.create_table(:books, :force => true) do |t|
  t.string :type
  t.integer :number
  t.integer :count, :null => false, :default => 1
  t.integer :user_id
  t.timestamp :timestamp
  t.text :stuff
  t.boolean :flag
end

if defined?(Rails::Railtie)
  DefaultValueFor.initialize_railtie
  DefaultValueFor.initialize_active_record_extensions
end

class DefaultValuePluginTest < TestCaseClass
  def around
    Object.const_set(:User, Class.new(ActiveRecord::Base))
    Object.const_set(:Book, Class.new(ActiveRecord::Base))
    Object.const_set(:Novel, Class.new(Book))
    User.has_many :books
    Book.belongs_to :user

    ActiveRecord::Base.transaction do
      yield
      raise ActiveRecord::Rollback
    end
  ensure
    Object.send(:remove_const, :User)
    Object.send(:remove_const, :Book)
    Object.send(:remove_const, :Novel)
    ActiveSupport::Dependencies.clear
  end

  def test_default_value_on_attribute_methods
    Book.class_eval do
      serialize :stuff
      default_value_for :color, :green
      def color; (self.stuff || {})[:color]; end
      def color=(val)
        self.stuff ||= {}
        self.stuff[:color] = val
      end
    end
    assert_equal :green, Book.create.color
  end

  def test_default_value_can_be_passed_as_argument
    Book.default_value_for(:number, 1234)
    assert_equal 1234, Book.new.number
  end

  def test_default_value_can_be_passed_as_block
    Book.default_value_for(:number) { 1234 }
    assert_equal 1234, Book.new.number
  end

  def test_works_with_create
    Book.default_value_for :number, 1234

    object = Book.create
    refute_nil Book.find_by_number(1234)

    # allows nil for existing records
    object.update_attribute(:number, nil)
    assert_nil Book.find_by_number(1234)
    assert_nil Book.find(object.id).number
  end

  def test_does_not_allow_nil_sets_default_value_on_existing_nils
    Book.default_value_for(:number, :allows_nil => false) { 1234 }
    object = Book.create
    object.update_attribute(:number, nil)
    assert_nil Book.find_by_number(1234)
    assert_equal 1234, Book.find(object.id).number
  end

  def test_overwrites_db_default
    Book.default_value_for :count, 1234
    assert_equal 1234, Book.new.count
  end

  def test_doesnt_overwrite_values_provided_by_mass_assignment
    Book.default_value_for :number, 1234
    assert_equal 1, Book.new(:number => 1, :count => 2).number
  end

  def test_doesnt_overwrite_values_provided_by_multiparameter_assignment
    Book.default_value_for :timestamp, Time.mktime(2000, 1, 1)
    timestamp = Time.mktime(2009, 1, 1)
    object = Book.new('timestamp(1i)' => '2009', 'timestamp(2i)' => '1', 'timestamp(3i)' => '1')
    assert_equal timestamp, object.timestamp
  end

  def test_doesnt_overwrite_values_provided_by_constructor_block
    Book.default_value_for :number, 1234
    object = Book.new do |x|
      x.number = 1
      x.count  = 2
    end
    assert_equal 1, object.number
  end

  def test_doesnt_overwrite_explicitly_provided_nil_values_in_mass_assignment
    Book.default_value_for :number, 1234
    assert_equal nil, Book.new(:number => nil).number
  end

  def test_overwrites_explicitly_provided_nil_values_in_mass_assignment
    Book.default_value_for :number, :value => 1234, :allows_nil => false
    assert_equal 1234, Book.new(:number => nil).number
  end

  def test_default_values_are_inherited
    Book.default_value_for :number, 1234
    assert_equal 1234, Novel.new.number
  end

  def test_default_values_in_superclass_are_saved_in_subclass
    Book.default_value_for :number, 1234
    Novel.default_value_for :flag, true
    object = Novel.create!
    assert_equal object.id, Novel.find_by_number(1234).id
    assert_equal object.id, Novel.find_by_flag(true).id
  end

  def test_default_values_in_subclass
    Novel.default_value_for :number, 5678
    assert_equal 5678, Novel.new.number
    assert_nil Book.new.number
  end

  def test_multiple_default_values_in_subclass_with_default_values_in_parent_class
    Book.class_eval do
      default_value_for :other_number, nil
      attr_accessor :other_number
    end
    Novel.default_value_for :number, 5678

    # Ensure second call in this class doesn't reset _default_attribute_values,
    # and also doesn't consider the parent class' _default_attribute_values when
    # making that check.
    Novel.default_value_for :user_id, 9999

    object = Novel.new
    assert_nil object.other_number
    assert_equal 5678, object.number
    assert_equal 9999, object.user_id
  end

  def test_override_default_values_in_subclass
    Book.default_value_for :number, 1234
    Novel.default_value_for :number, 5678
    assert_equal 5678, Novel.new.number
    assert_equal 1234, Book.new.number
  end

  def test_default_values_in_subclass_do_not_affect_parent_class
    Book.default_value_for :number, 1234
    Novel.class_eval do
      default_value_for :hello, "hi"
      attr_accessor :hello
    end

    assert Book.new
    assert !Book._default_attribute_values.include?(:hello)
  end

  def test_doesnt_set_default_on_saved_records
    Book.create(:number => 9876)
    Book.default_value_for :number, 1234
    assert_equal 9876, Book.first.number
  end

  def test_also_works_on_attributes_that_arent_database_columns
    Book.class_eval do
      default_value_for :hello, "hi"
      attr_accessor :hello
    end
    assert_equal 'hi', Book.new.hello
  end

  def test_doesnt_conflict_with_overrided_initialize_method_in_model_class
    Book.class_eval do
      def initialize(attrs = {})
        @initialized = true
        super(:count => 5678)
      end

      default_value_for :number, 1234
    end
    object = Book.new
    assert_equal 1234, object.number
    assert_equal 5678, object.count
    assert object.instance_variable_get('@initialized')
  end

  def test_model_instance_is_passed_to_the_given_block
    instance = nil
    Book.default_value_for :number do |n|
      instance = n
    end
    object = Book.new
    assert_same object.object_id, instance.object_id
  end

  def test_can_specify_default_value_via_association
    user = User.create(:username => 'Kanako', :default_number => 123)
    Book.default_value_for :number do |n|
      n.user.default_number
    end
    assert_equal 123, user.books.create!.number
  end

  def test_default_values
    Book.default_values({
      :type      => "normal",
      :number    => lambda { 10 + 5 },
      :timestamp => lambda {|_| Time.now }
    })

    object = Book.new
    assert_equal("normal", object.type)
    assert_equal(15, object.number)
  end

  def test_default_value_order
    Book.default_value_for :count, 5
    Book.default_value_for :number do |this|
      this.count * 2
    end
    object = Book.new
    assert_equal(5, object.count)
    assert_equal(10, object.number)
  end

  def test_attributes_with_default_values_are_not_marked_as_changed
    Book.default_value_for :count, 5
    Book.default_value_for :number, 2

    object = Book.new
    assert(!object.changed?)
    assert_equal([], object.changed)

    object.type = "foo"
    assert(object.changed?)
    assert_equal(["type"], object.changed)
  end

  def test_default_values_are_duplicated
    User.default_value_for :username, "hello"
    user1 = User.new
    user1.username << " world"
    user2 = User.new
    assert_equal("hello", user2.username)
  end

  def test_default_values_are_shallow_copied
    User.class_eval do
      attr_accessor :hash
      default_value_for :hash, { 1 => [] }
    end
    user1 = User.new
    user1.hash[1] << 1
    user2 = User.new
    assert_equal([1], user2.hash[1])
  end

  def test_constructor_does_not_affect_the_hash_passed_to_it
    Book.default_value_for :count, 5
    options = { :count => 5, :user_id => 1 }
    options_dup = options.dup
    Book.new(options)
    assert_equal(options_dup, options)
  end

  def test_subclass_find
    Book.default_value_for :number, 5678
    n = Novel.create
    assert Novel.find(n.id)
  end

  def test_does_not_see_false_as_blank_at_boolean_columns_for_existing_records
    Book.default_value_for(:flag, :allows_nil => false) { true }

    object = Book.create

    # allows nil for existing records
    object.update_attribute(:flag, false)
    assert_equal false, Book.find(object.id).flag
  end

  def test_works_with_nested_attributes
    User.accepts_nested_attributes_for :books
    User.default_value_for :books do
      [Book.create!(:number => 0)]
    end

    user = User.create! :books_attributes => [{:number => 1}]
    assert_equal 1, Book.all.first.number
  end

  if ActiveRecord::VERSION::MAJOR == 3
    def test_constructor_ignores_forbidden_mass_assignment_attributes
      Book.class_eval do
        default_value_for :number, 1234
        attr_protected :number
      end
      object = Book.new(:number => 5678, :count => 987)
      assert_equal 1234, object.number
      assert_equal 987, object.count
    end

    def test_constructor_respects_without_protection_option
      Book.class_eval do
        default_value_for :number, 1234
        attr_protected :number
      end

      object = Book.create!({:number => 5678, :count => 987}, :without_protection => true)
      assert_equal 5678, object.number
      assert_equal 987, object.count
    end
  end
end
