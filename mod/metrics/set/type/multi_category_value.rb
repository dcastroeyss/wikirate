include_set CategoryValue

format :html do
  def editor
    options_count > 10 ? :multiselect : :checkbox
  end
end

format :json do
  view :core do
    card.raw_value
  end
end
