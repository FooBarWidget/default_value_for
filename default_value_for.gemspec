Gem::Specification.new do |s|
  s.name                  = 'default_value_for'
  s.version               = '3.3.0'
  s.summary               = 'Provides a way to specify default values for ActiveRecord models'
  s.description           = 'The default_value_for plugin allows one to define default values for ActiveRecord models in a declarative manner'
  s.email                 = 'software-signing@phusion.nl'
  s.homepage              = 'https://github.com/FooBarWidget/default_value_for'
  s.authors               = ['Hongli Lai']
  s.license               = 'MIT'
  s.required_ruby_version = '>= 1.9.3'
  s.files                 = ['default_value_for.gemspec',
                             'LICENSE.TXT', 'Rakefile', 'README.md', 'test.rb',
                             'init.rb',
                             'lib/default_value_for.rb',
                             'lib/default_value_for/railtie.rb']
  s.add_dependency 'activerecord', '>= 3.2.0', '< 6.2'
  s.add_development_dependency 'actionpack', '>= 3.2.0', '< 6.1'
  s.add_development_dependency 'appraisal'
  s.add_development_dependency 'minitest', '>= 4.2'
  s.add_development_dependency 'minitest-around'
  s.add_development_dependency 'railties', '>= 3.2.0', '< 6.1'
end
