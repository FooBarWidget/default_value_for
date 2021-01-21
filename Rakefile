task :default => :test

desc "Run unit tests."
task :test do
  ruby "test.rb"
end

rails_versions = %w(
  3.2
  4.0
  4.1
  4.2
  5.0
  5.1
  5.2
  6.0
  6.1
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
      ENV['BUNDLE_GEMFILE'] = "gemfiles/rails_#{dotless}.gemfile"
      ruby "test.rb"
    end
  end
end

namespace :test do
  desc "Test with all supported Rails versions"
  task :railsall do
    rails_versions.each do |version|
      dotless = version.delete('.')
      ENV['BUNDLE_GEMFILE'] = "gemfiles/rails_#{dotless}.gemfile"
      ruby "test.rb"
    end
  end
end
