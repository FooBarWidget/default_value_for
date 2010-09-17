# Rails 3 initialization
module DefaultValueForPlugin
	if defined? Rails::Railtie
		require 'rails'
		class Railtie < Rails::Railtie
			initializer 'default_value_for.insert_into_active_record' do
				ActiveSupport.on_load :active_record do
					ActiveRecord::Base.extend(DefaultValueForPlugin::ClassMethods)
				end
			end
		end
	end
end
