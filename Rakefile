task :default => :test

desc "Run unit tests."
task :test do
  ruby "test.rb"
end

['3.2', '4.0', '4.1', '4.2', '5.0', '5.1'].each do |version|
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
