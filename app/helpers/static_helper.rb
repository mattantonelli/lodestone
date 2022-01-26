module StaticHelper
  def locale_options
    options_for_select([['North America', 'na'], ['Europe', 'eu'], ['France', 'fr'], ['Deutschland', 'de'], ['日本', 'jp']],
                       params[:locale])
  end
end
