task :default => :test

desc "Run unit tests."
task :test do
  ruby "test.rb"
end

['3.2', '4.0', '4.1', '4.2'].each do |version|
  dotless = version.delete('.')

  namespace :bundle do
    desc "Bundle with Rails #{version}.x"
    task :"rails#{dotless}" do
      ENV['BUNDLE_GEMFILE'] = "Gemfile.rails.#{version}.rb"
      sh "bundle"
    end
  end

  namespace :test do
    desc "Test with Rails #{version}.x"
    task :"rails#{dotless}" do
      ENV['BUNDLE_GEMFILE'] = "Gemfile.rails.#{version}.rb"
      ruby "test.rb"
    end
  end
end
