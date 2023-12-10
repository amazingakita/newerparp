require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

if ['development', 'test'].include? ENV['RAILS_ENV']
  Dotenv::Railtie.load
end

class SkippingSassCompressor
  def compress(string)
    options = { syntax: :scss, cache: false, read_cache: false, style: :compressed}
    begin
      Sprockets::Autoload::SassC::Engine.new(string, options).render
    rescue => e
      puts "Could not compress '#{string[0..65]}'...: #{e.message}, skipping compression"
      string
    end
  end
end

module Newerparp
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.1

    # Please, see https://guides.rubyonrails.org/autoloading_and_reloading_constants.html#config-autoload-lib-ignore.
    config.autoload_lib(ignore: %w(assets tasks))

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    config.assets.css_compressor = SkippingSassCompressor.new
  end
end
