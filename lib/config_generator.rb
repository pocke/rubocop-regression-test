require 'rubocop'
require 'yaml'
require 'fileutils'
require_relative './rubocop_adapter'

module ConfigGenerator
  extend self

  BASE_DIRECTORY = '/tmp/rubocop-regression-test/config'
  FileUtils.mkdir_p(BASE_DIRECTORY) unless File.directory?(BASE_DIRECTORY)

  # @return [Array<String>]
  def generate_configs
    cop_configs = RuboCopAdapter.configurable_cops.map do |cop_name|
      cop_configs(cop_name)
    end
    max = cop_configs.max_by(&:size).size
    cop_configs.each do |c|
      c.fill(nil, c.size..(max-1))
    end

    rubocop_yml_contents = cop_configs.transpose.map do |conf_set|
      compacted = conf_set.compact
      compacted.inject({}) do |a, b|
        a.merge(b)
      end
    end

    res = rubocop_yml_contents.map do |content|
      tmppath = File.join(BASE_DIRECTORY, Time.now.to_f.to_s + '.yml')
      cop_names = content.keys
      File.write(tmppath, content.to_yaml)
      [tmppath, cop_names]
    end
    res.push([File.expand_path('../config/enabled_by_default.yml', __dir__), nil])
    res
  end

  private

  def cop_configs(cop_name)
    cop_config = RuboCopAdapter.default_config[cop_name]

    # e.g. %w[EnforcedHashRocketStyle EnforcedColonStyle EnforcedLastArgumentHashStyle]
    enforced_style_names = RuboCopAdapter.enforced_styles(cop_config)

    # e.g. [
    #   %w[key separator table],
    #   %w[key separator table],
    #   w[always_inspect always_ignore ignore_implicit ignore_explicit],
    # ]
    supported_styles = enforced_style_names
      .map{|style_name| RuboCopAdapter.to_supported_styles(style_name)}
      .map{|supported_style_name| cop_config[supported_style_name]}

    supported_styles[0].product(*supported_styles[1..-1]).map do |style_values|
      conf = style_values
        .map.with_index{|value, idx| [enforced_style_names[idx], value]}
        .to_h
      conf['Enabled'] = true
      {
        cop_name => conf
      }
    end
  end
end
