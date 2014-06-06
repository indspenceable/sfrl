class ItemBase
  attr_reader :cost, :cooldown, :install_cost

  def long_description
    [
      [pretty, 'white'],
      ['', 'white'],
      ["Install Cost: #{install_cost}", 'white'],
      ["Cooldown: #{cooldown}", 'white'],
      ["Energy Cost: #{cost}", 'white'],
    ] + item_specific_description
  end
end
