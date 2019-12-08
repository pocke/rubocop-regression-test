module RuboCopAdapter
  extend self

  def default_config
    RuboCop::ConfigLoader.default_configuration
  end

  def configurable_cops
    default_config.to_h
      .reject{|key, cop_conf| enforced_styles(cop_conf).empty? }
      .keys.sort
  end


  def enforced_styles(cop_conf)
    cop_conf.keys.select do |key|
      key.start_with?('Enforced')
    end
  end
  
  def to_supported_styles(enforced_style)
    RuboCop::Cop::Util.to_supported_styles(enforced_style)
  end
end
