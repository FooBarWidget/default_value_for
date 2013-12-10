task :default => :test

desc "Run unit tests."
task :test do
  ruby "test.rb"
end

namespace :test do

  task :rails32 do
    ENV['BUNDLE_GEMFILE'] = 'Gemfile.rails.3.2.rb'
    ruby "test.rb"
  end

  task :rails40 do
    ENV['BUNDLE_GEMFILE'] = 'Gemfile.rails.4.0.rb'
    ruby "test.rb"
  end

end
