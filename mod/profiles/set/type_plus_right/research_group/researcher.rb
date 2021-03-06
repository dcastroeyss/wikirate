CONTRIBUTION_CATEGORIES = %i[created updated discussed double_checked].freeze
CONTRIBUTION_CATEGORY_HEADER = ["Answers"].concat(
  CONTRIBUTION_CATEGORIES.map do |category|
    Card::Set::LtypeRtype::User::Cardtype::ACTION_LABELS[category]
  end
)

def ok_to_join?
  Auth.signed_in? && !current_user_is_member?
end

def current_user_is_member?
  item_cards.find { |item_card| item_card.id == Auth.current_id }
end

def joining?
  Env.params[:join].present?
end

def leaving?
  Env.params[:leave].present?
end

event :join_group, :validate, when: :joining? do
  abort :failure, "cannot join this group" unless ok_to_join?
  add_item Auth.current.name
end

event :leave_group, :validate, when: :leaving? do
  drop_item Auth.current.name
end

format :html do
  view :overview, tags: :unknown_ok do
    wrap { haml :overview }
  end

  view :contributions, tags: :unknown_ok, cache: :never do
    return "" unless card.count.positive?
    with_paging do |paging_args|
      table_content = member_contribution_content members_on_page(paging_args)
      table table_content, header: CONTRIBUTION_CATEGORY_HEADER
    end
  end

  def members_on_page paging_args
    wql = { referred_to_by: card.name, type_id: UserID, sort: :name }
    Card.search wql.merge!(paging_args.extract!(:limit, :offset))
  end

  def self.membership_button action, test, btnclass
    view "#{action}_button".to_sym, tags: :unknown_ok, denial: :blank, cache: :never,
                                    perms: ->(r) { r.card.send test } do
      link_to "#{action.to_s.capitalize} Group",
              path: { action: :update, action => true, success: { view: :overview } },
              class: "btn #{btnclass} btn-sm slotter",
              remote: true
    end
  end

  membership_button :join, :ok_to_join?, "btn-primary"
  membership_button :leave, :current_user_is_member?, "btn-outline-primary"

  view :manage_button, tags: :unknown_ok do
    link_to_view "edit",
                 "Manage Researcher List",
                 class: "btn btn-outline-primary btn-sm slotter"
  end

  def member_contribution_content members
    members.map do |member|
      [nest(member, view: :thumbnail)].concat contribution_counts(member)
    end
  end

  def contribution_counts member
    CONTRIBUTION_CATEGORIES.map do |category|
      card.left.contribution_count member.name, :metric_answer, category
    end
  end
end
