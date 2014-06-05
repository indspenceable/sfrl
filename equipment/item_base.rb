class ItemBase
  def long_description
    [
      [pretty, 'white'],
      ['', 'white'],
      ["Cooldown: #{cooldown}", 'white'],
      ["Energy Cost: #{cost}", 'white'],
    ] + item_specific_description
  end
end
