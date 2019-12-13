class ExecuteId
  def self.encode(config_number:, auto_correct:)
    "#{config_number}-#{auto_correct}"
  end

  def self.decode(id)
    n, a = id.split('-')
    {
      config_number: n.to_i,
      auto_correct: a == 'true',
    }
  end
end
