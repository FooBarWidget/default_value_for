Gem::Specification.new do |s|
  s.name                  = %q{default_value_for}
  s.version               = "4.0.0"
  s.summary               = %q{Provides a way to specify default values for ActiveRecord models}
  s.description           = %q{The default_value_for plugin allows one to define default values for ActiveRecord models in a declarative manner}
  s.email                 = %q{software-signing@phusion.nl}
  s.homepage              = %q{https://github.com/FooBarWidget/default_value_for}
  s.authors               = ["Hongli Lai"]
  s.license               = 'MIT'
  s.required_ruby_version = '>= 3.0.0'
  s.files                 = ['default_value_for.gemspec',
    'LICENSE.TXT', 'Rakefile', 'README.md', 'test.rb',
    'init.rb',
    'lib/default_value_for.rb',
    'lib/default_value_for/railtie.rb'
  ]
  s.add_dependency 'activerecord', '>= 6.1', '< 8.1'
  s.add_development_dependency 'actionpack', '>= 6.1', '< 8.1'
  s.add_development_dependency 'railties', '>= 6.1', '< 8.1'
  s.add_development_dependency 'minitest', '>= 5.0'
  s.add_development_dependency 'minitest-around'
  s.add_development_dependency 'appraisal'
  s.add_development_dependency 'bundler'
end
