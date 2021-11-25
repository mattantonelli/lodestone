module StaticHelper
  def locale_options
    options_for_select([['North America', 'na'], ['Europe', 'eu'], ['France', 'fr'], ['Germany', 'de'], ['Japan', 'jp']],
                       params[:locale])
  end
end
