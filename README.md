# Introduction

The default_value_for plugin allows one to define default values for ActiveRecord
models in a declarative manner. For example:

```ruby
class User < ActiveRecord::Base
  default_value_for :name, "(no name)"
  default_value_for :last_seen do
    Time.now
  end
end

u = User.new
u.name       # => "(no name)"
u.last_seen  # => Mon Sep 22 17:28:38 +0200 2008
```

*Note*: critics might be interested in the "When (not) to use default_value_for?" section. Please read on.

## Installation

### Rails 3.2 - 4.2 / Ruby 1.9.3 and higher

The current version of default_value_for (3.0.x) is compatible with Rails 3.2 or higher, and Ruby 1.9.3 and higher.

Add it to your Gemfile:

```ruby
gem "default_value_for", "~> 3.0.0"
```

This gem is signed using PGP with the Phusion Software Signing key: http://www.phusion.nl/about/gpg. That key in turn is signed by the rubygems-openpgp Certificate Authority: http://www.rubygems-openpgp-ca.org/.

You can verify the authenticity of the gem by following The Complete Guide to Verifying Gems with rubygems-openpgp: http://www.rubygems-openpgp-ca.org/blog/the-complete-guide-to-verifying-gems-with-rubygems-openpgp.html

## Rails 3.0 - 3.1 / Ruby 1.9.3 and lower

To use default_value_for with older versions of Ruby and Rails, you must use the previous stable release, 2.0.3. This version works with Rails 3.0, 3.1, and 3.2; and Ruby 1.8.7 and higher. It **does not** work with Rails 4.

```ruby
gem "default_value_for", "~> 2.0.3"
```

### Rails 2

To use default_value_for with Rails 2.x you must use an older version:

```shell
./script/plugin install git://github.com/FooBarWidget/default_value_for.git -r release-1.0.7
```

## The default_value_for method

The `default_value_for` method is available in all ActiveRecord model classes.

The first argument is the name of the attribute for which a default value should
be set. This may either be a Symbol or a String.

The default value itself may either be passed as the second argument:

```ruby
  default_value_for :age, 20
```

...or it may be passed as the return value of a block:

```ruby
  default_value_for :age do
    if today_is_sunday?
      20
    else
      30
    end
  end
```

If you pass a value argument, then the default value is static and never changes. However, if you pass a block, then the default value is retrieved by calling the block. This block is called not once, but every time a new record is instantiated and default values need to be filled in.

The latter form is especially useful if your model has a UUID column. One can generate a new, random UUID for every newly instantiated record:

```ruby
class User < ActiveRecord::Base
  default_value_for :uuid do
    UuidGenerator.new.generate_uuid
  end
end

User.new.uuid  # => "51d6d6846f1d1b5c9a...."
User.new.uuid  # => "ede292289e3484cb88...."
```

Note that record is passed to the block as an argument, in case you need it for whatever reason:

```ruby
class User < ActiveRecord::Base
  default_value_for :uuid do |x|
    x   # <--- a User object
    UuidGenerator.new.generate_uuid
  end
end
```

## default_value_for options

* allows_nil (default: true) - Sets explicitly passed nil values if option is set to true.

You can pass this options hash as 2nd parameter and have to pass the default value through the :value option in this case e.g.:

```ruby
default_value_for :age, :value => 20, :allows_nil => false
```

You can still pass the default value through a block:

```ruby
default_value_for :uuid, :allows_nil => false do
  UuidGenerator.new.generate_uuid
end
````

## The default_values method

As a shortcut, you can use +default_values+ to set multiple default values at once.

```ruby
default_values :age  => 20,
               :uuid => lambda { UuidGenerator.new.generate_uuid }
```

If you like to override default_value_for options for each attribute you can do so:

```ruby
default_values :age  => { :value => 20 },
               :uuid => { :value => lambda { UuidGenerator.new.generate_uuid }, :allows_nil => false }
```

The difference is purely aesthetic.  If you have lots of default values which are constants or constructed with one-line blocks, +default_values+ may look nicer.  If you have default values constructed by longer blocks, `default_value_for` suit you better.  Feel free to mix and match.

As a side note, due to specifics of Ruby's parser, you cannot say,

```ruby
default_value_for :uuid { UuidGenerator.new.generate_uuid }
```

because it will not parse. One needs to write

```ruby
default_value_for(:uuid) { UuidGenerator.new.generate_uuid }
```

instead. This is in part the inspiration for the +default_values+ syntax.

## Rules

### Instantiation of new record

Upon instantiating a new record, the declared default values are filled into
the record. You've already seen this in the above examples.

### Retrieval of existing record

Upon retrieving an existing record in the following case, the declared default values are _not_ filled into the record. Consider the example with the UUID:

```ruby
user = User.create
user.uuid   # => "529c91b8bbd3e..."

user = User.find(user.id)
# UUID remains unchanged because it's retrieved from the database!
user.uuid   # => "529c91b8bbd3e..."
```

But when the declared default value is set to not allow nil and nil is passed the default values will be set on retrieval.
Consider this example:

```ruby
default_value_for(:number, :allows_nil => false) { 123 }

user = User.create

# manual SQL by-passing active record and the default value for gem logic through ActiveRecord's after_initialize callback
user.update_attribute(:number, nil)

# declared default value should be set
User.find(user.id).number # => 123 # = declared default value
```

### Mass-assignment

If a certain attribute is being assigned via the model constructor's
mass-assignment argument, that the default value for that attribute will _not_
be filled in:

```ruby
user = User.new(:uuid => "hello")
user.uuid   # => "hello"
```

However, if that attribute is protected by +attr_protected+ or +attr_accessible+,
then it will be filled in:

```ruby
class User < ActiveRecord::Base
  default_value_for :name, 'Joe'
  attr_protected :name
end

user = User.new(:name => "Jane")
user.name   # => "Joe"

# the without protection option will work as expected
user = User.new({:name => "Jane"}, :without_protection => true)
user.name   # => "Jane"
```

Explicitly set nil values for accessible attributes will be accepted:

```ruby
class User < ActiveRecord::Base
  default_value_for :name, 'Joe'
end

user = User(:name => nil)
user.name # => nil

... unless the accessible attribute is set to not allowing nil:

class User < ActiveRecord::Base
  default_value_for :name, 'Joe', :allows_nil => false
end

user = User(:name => nil)
user.name # => "Joe"
```

### Inheritance

Inheritance works as expected. All default values are inherited by the child
class:

```ruby
class User < ActiveRecord::Base
  default_value_for :name, 'Joe'
end

class SuperUser < User
end

SuperUser.new.name   # => "Joe"
```

### Attributes that aren't database columns

`default_value_for` also works with attributes that aren't database columns.
It works with anything for which there's an assignment method:

```ruby
# Suppose that your 'users' table only has a 'name' column.
class User < ActiveRecord::Base
  default_value_for :name, 'Joe'
  default_value_for :age, 20
  default_value_for :registering, true

  attr_accessor :age

  def registering=(value)
    @registering = true
  end
end

user = User.new
user.age    # => 20
user.instance_variable_get('@registering')    # => true
```

### Default values are duplicated

The given default values are duplicated when they are filled in, so if you mutate a value that was filled in with a default value, then it will not affect all subsequent default values:

```ruby
class Author < ActiveRecord::Base
  # This model only has a 'name' attribute.
end

class Book < ActiveRecord::Base
  belongs_to :author

  # By default, a Book belongs to a new, unsaved author.
  default_value_for :author, Author.new
end

book1 = Book.new
book1.author.name  # => nil
# This does not mutate the default value:
book1.author.name = "John"

book2 = Book.new
book2.author.name  # => nil
```

However the duplication is shallow. If you modify any objects that are referenced by the default value then it will affect subsequent default values:

```ruby
class Author < ActiveRecord::Base
  attr_accessor :useless_hash
  default_value_for :useless_hash, { :foo => [] }
end

author1 = Author.new
author1.useless_hash    # => { :foo => [] }
# This mutates the referred array:
author1.useless_hash[:foo] << 1

author2 = Author.new
author2.useless_hash    # => { :foo => [1] }
```

You can prevent this from happening by passing a block to `default_value_for`, which returns a new object instance with fresh references every time:

```ruby
class Author < ActiveRecord::Base
  attr_accessor :useless_hash
  default_value_for :useless_hash do
    { :foo => [] }
  end
end

author1 = Author.new
author1.useless_hash    # => { :foo => [] }
author1.useless_hash[:foo] << 1

author2 = Author.new
author2.useless_hash    # => { :foo => [] }
```

### Caveats

A conflict can occur if your model class overrides the 'initialize' method, because this plugin overrides 'initialize' as well to do its job.

```ruby
class User < ActiveRecord::Base
  def initialize  # <-- this constructor causes problems
    super(:name => 'Name cannot be changed in constructor')
  end
end
```

We recommend you to alias chain your initialize method in models where you use `default_value_for`:

```ruby
class User < ActiveRecord::Base
  default_value_for :age, 20

  def initialize_with_my_app
    initialize_without_my_app(:name => 'Name cannot be changed in constructor')
  end

  alias_method_chain :initialize, :my_app
end
```

Also, stick with the following rules:

* There is no need to +alias_method_chain+ your initialize method in models that don't use `default_value_for`.

* Make sure that +alias_method_chain+ is called *after* the last `default_value_for` occurance.

If your default value is accidentally similar to default_value_for's options hash wrap your default value like this:

```ruby
default_value_for :attribute_name, :value => { :value => 123, :other_value => 1234 }
```

## When (not) to use default_value_for?

You can also specify default values in the database schema. For example, you can specify a default value in a migration as follows:

```ruby
create_table :users do |t|
  t.string    :username,  :null => false, :default => 'default username'
  t.integer   :age,       :null => false, :default => 20
end
```

This has similar effects as passing the default value as the second argument to `default_value_for`:

```ruby
default_value_for(:username, 'default_username')
default_value_for(:age, 20)
```

Default values are filled in whether you use the schema defaults or the default_value_for defaults:

```ruby
user = User.new
user.username   # => 'default username'
user.age        # => 20
```

It's recommended that you use this over `default_value_for` whenever possible.

However, it's not possible to specify a schema default for serialized columns. With `default_value_for`, you can:

```ruby
class User < ActiveRecord::Base
  serialize :color
  default_value_for :color, [255, 0, 0]
end
```

And if schema defaults don't provide the flexibility that you need, then `default_value_for` is the perfect choice. For example, with `default_value_for` you could specify a per-environment default:

```ruby
class User < ActiveRecord::Base
  if Rails.env ## "development"
    default_value_for :is_admin, true
  end
end
```

Or, as you've seen in an earlier example, you can use `default_value_for` to generate a default random UUID:

```ruby
class User < ActiveRecord::Base
  default_value_for :uuid do
    UuidGenerator.new.generate_uuid
  end
end
```

Or you could use it to generate a timestamp that's relative to the time at which the record is instantiated:

```ruby
class User < ActiveRecord::Base
  default_value_for :account_expires_at do
    3.years.from_now
  end
end

User.new.account_expires_at   # => Mon Sep 22 18:43:42 +0200 2008
sleep(2)
User.new.account_expires_at   # => Mon Sep 22 18:43:44 +0200 2008
```

Finally, it's also possible to specify a default via an association:

```ruby
# Has columns: 'name' and 'default_price'
class SuperMarket < ActiveRecord::Base
  has_many :products
end

# Has columns: 'name' and 'price'
class Product < ActiveRecord::Base
  belongs_to :super_market

  default_value_for :price do |product|
    product.super_market.default_price
  end
end

super_market = SuperMarket.create(:name => 'Albert Zwijn', :default_price => 100)
soap = super_market.products.create(:name => 'Soap')
soap.price   # => 100
```

### What about before_validate/before_save?

True, +before_validate+ and +before_save+ does what we want if we're only interested in filling in a default before saving. However, if one wants to be able to access the default value even before saving, then be prepared to write a lot of code. Suppose that we want to be able to access a new record's UUID, even before it's saved. We could end up with the following code:

```ruby
# In the controller
def create
  @user = User.new(params[:user])
  @user.generate_uuid
  email_report_to_admin("#{@user.username} with UUID #{@user.uuid} created.")
  @user.save!
end

# Model
class User < ActiveRecord::Base
  before_save :generate_uuid_if_necessary

  def generate_uuid
    self.uuid = ...
  end

  private
    def generate_uuid_if_necessary
      if uuid.blank?
        generate_uuid
      end
    end
end
```

The need to manually call +generate_uuid+ here is ugly, and one can easily forget to do that. Can we do better? Let's see:

```ruby
# Controller
def create
  @user = User.new(params[:user])
  email_report_to_admin("#{@user.username} with UUID #{@user.uuid} created.")
  @user.save!
end

# Model
class User < ActiveRecord::Base
  before_save :generate_uuid_if_necessary

  def uuid
    value = read_attribute('uuid')
    if !value
      value = generate_uuid
      write_attribute('uuid', value)
    end
    value
  end

  # We need to override this too, otherwise User.new.attributes won't return
  # a default UUID value. I've never tested with User.create() so maybe we
  # need to override even more things.
  def attributes
    uuid
    super
  end

  private
    def generate_uuid_if_necessary
      uuid  # Reader method automatically generates UUID if it doesn't exist
    end
end
```

That's an awful lot of code. Using `default_value_for` is easier, don't you think?

### What about other plugins?

I've only been able to find 2 similar plugins:

* Default Value: http://agilewebdevelopment.com/plugins/default_value

* ActiveRecord Defaults: http://agilewebdevelopment.com/plugins/activerecord_defaults

'Default Value' appears to be unmaintained; its SVN link is broken. This leaves only 'ActiveRecord Defaults'. However, it is semantically dubious, which leaves it wide open for corner cases. For example, it is not clearly specified what ActiveRecord Defaults will do when attributes are protected by +attr_protected+ or +attr_accessible+. It is also not clearly specified what one is supposed to do if one needs a custom +initialize+ method in the model.

I've taken my time to thoroughly document default_value_for's behavior.

## Credits

I've wanted such functionality for a while now and it baffled me that ActiveRecord doesn't provide a clean way for me to specify default values. After reading http://groups.google.com/group/rubyonrails-core/browse_thread/thread/b509a2fe2b62ac5/3e8243fa1954a935, it became clear that someone needs to write a plugin. This is the result.

Thanks to Pratik Naik for providing the initial code snippet on which this plugin is based on: http://m.onkey.org/2007/7/24/how-to-set-default-values-in-your-model

Thanks to Norman Clarke and Tom Mango for Rails 4 support.