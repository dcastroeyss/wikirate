format :html do
  def with_header header, level: 3
    output [wrap_with("h#{level}", header), yield]
  end

  def standard_pointer_nest codename
    field_nest codename, view: :titled,
                         cache: :never,
                         title: codename.cardname.s,
                         variant: "plural capitalized",
                         items: { view: :link }
  end

  def original_link url, opts={}
    text = opts.delete(:text) || "Visit Original"
    link_to text, opts.merge(path: url)
  end
end

