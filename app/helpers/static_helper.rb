module StaticHelper
  def locale_options(selected)
    options_for_select([['North America', 'na'], ['Europe / Oceania', 'eu'], ['France', 'fr'], ['Deutschland', 'de'], ['日本', 'jp']],
                       selected)
  end
end
