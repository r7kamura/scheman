require "schema_manager"
require "pathname"

RSpec.configure do |config|
  config.treat_symbols_as_metadata_keys_with_true_values = true
  config.run_all_when_everything_filtered = true
  config.filter_run :focus
  config.add_setting :root, default: Pathname.new(File.expand_path("../../", __FILE__))
end
