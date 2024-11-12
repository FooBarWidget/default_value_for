task :default => :test

require "bundler/gem_tasks"

desc "Run unit tests."
task :test do
  ruby "test.rb"
end

rails_versions = %w(
  6.1
  7.0
  7.1
  7.2
  8.0
)

rails_versions.each do |version|
  dotless = version.delete('.')

  namespace :bundle do
    desc "Bundle with Rails #{version}.x"
    task :"rails#{dotless}" do
      ENV['BUNDLE_GEMFILE'] = "gemfiles/rails_#{dotless}.gemfile"
      sh "bundle"
    end
  end

  namespace :test do
    desc "Test with Rails #{version}.x"
    task :"rails#{dotless}" do
      sh 'appraisal install'
      ENV['BUNDLE_GEMFILE'] = "gemfiles/rails_#{dotless}.gemfile"
      ruby "test.rb"
    end
  end
end

namespace :test do
  desc "Test with all supported Rails versions"
  task :railsall do
    sh 'appraisal install'
    rails_versions.each do |version|
      dotless = version.delete('.')
      ENV['BUNDLE_GEMFILE'] = "gemfiles/rails_#{dotless}.gemfile"
      ruby "test.rb"
    end
  end
end
