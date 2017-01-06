include_set Abstract::WikirateTable # deprecated, but not clear if it is still used
include_set Abstract::MetricChild, generation: 1
include_set Abstract::Table

def latest_value_year
  cached_count
end

def latest_value_card
  return if !(lvy = latest_value_year) || lvy == 0
  Card.fetch cardname, lvy.to_s
end

def virtual?
  true
end

format :html do
  def all_answers
    @result ||=
      Answer.fetch({ record_id: card.id }, sort_by: :year, sort_order: :desc)
  end

  # used in four places:
  # 1) metric page -> company table -> item -> table on right side
  # 2) company page -> metric table -> teim ->  table on right side
  # 3) metric record page
  # 4) add new value page (new_metric_value view for company)

  view :core, unknown_ok: true do
    output [
             _optional_render_metric_info,
             _optional_render_buttons,
             _render_value_table
           ]
  end

  view :content do
    class_up "card_slot", "_append_new_value_form" if all_answers.empty?
    super()
  end

  view :buttons do
    return "" unless metric_card.metric_type_codename == :researched
    voo.show :timeline_header_buttons
    wrap_with :div, class: "timeline-header timeline-row " do
      output [add_answer_button, methodology_button]
    end
  end

  view :metric_info do
    wrap_with :div, class: "metric-info" do
      [
        _optional_render_question,
        _optional_render_methodology
      ]
    end
  end

  view :question do
    <<-HTML
      <div class="col-md-12 padding-bottom-10">
        #{nest(metric_card, view: :question_row)}
      </div>
    HTML
  end

  view :methodology do
    <<-HTML
      <div class="col-md-12">
        <div id="methodology-info" class="collapse">
            <div class="row"><small><strong>Methodology </strong>
              #{nest metric_card.methodology_card, view: :content,
                     items: { view: :link } }
            </small></div>
            <div class="row">
              <div class="row-icon">
                <i class="fa fa-tag"></i>
              </div>
              <div class="row-data">
                #{nest metric_card.fetch(trait: :wikirate_topic),
                       view: :content, items: { view: :link }}
              </div>
            </div>
        </div>
      </div>
    HTML
  end

  view :value_table do
    answer_view =
      voo.show?(:chart) ? :closed_answer : :closed_answer_without_chart

    # add answer button is above this view so we need
    # js to show it
    if voo.show? :add_answer_button
      class_up "card-slot", "_show_add_new_value_button"
    end
    wrap do
      wikirate_table :plain, all_answers,
                     [:plain_year, answer_view],
                     header: %w(Year Answer),
                     td: { classes: ["text-center"] }
    end
  end

  def default_menu_args args
    args[:optional_horizontal_menu] = :hide
  end

  def header_button text, klasses, data
    shared_data = { collapse: ".metric_value_form_container" }
    wrap_with :a, text, class: css_classes(button_classes, klasses),
              data: shared_data.merge(data)
  end

  def button_classes
    "btn btn-sm btn-default margin-12"
  end

  def add_answer_button
    header_button "Add answer",
                  "_add_new_value btn-primary",
                  company: company_name.url_key,
                  metric: metric_name.url_key,
                  toggle: "collapse-next",
                  parent: ".timeline-data"
  end

  def methodology_button
    target_id = card.cardname.url_key
    header_button "View Methodology",
                  "_view_methodology",
                  toggle: "collapse",
                  target: "[id='#{target_id}'] #methodology-info",
                  collapse: ".metric_value_form_container"
  end

  def metric_page_button
    link_to_card card.metric_card, "#{fa_icon "page"} Metric Page", class: button_classes
  end


  view :all_values do |args|
    wql = {
      left: card.name,
      type: Card::MetricValueID,
      sort: "name",
      dir: "desc"
    }
    wql_comment = "all metric values where metric = #{card.name}"
    Card.search(wql, wql_comment).map.with_index do |v, i|
      <<-HTML
        <span data-year="#{v.year}" data-value="#{v.value}"
              #{'style="display: none;"' if i > 0}>
          #{subformat(v).render_concise(args)}
        </span>
      HTML
    end.join("\n")
  end

  view :image_link do
    # TODO: change the css so that we don't need the extra logo class here
    #   and we can use a logo_link view on the type/company set
    text = wrap_with :div, class: "logo" do
      card.company_card.format.field_nest :image, view: :core, size: "small"
    end
    link_to_card card.company_card, text, class: "inherit-anchor hidden-xs"
  end

  view :name_link do
    link_to_card card.company_card, nil, class: "inherit-anchor name",
                                         target: "_blank"
  end
end
