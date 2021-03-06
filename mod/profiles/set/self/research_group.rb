def subvariants
  { created: [:submitted, :organized] }
end

def created_query user_id, variant=nil
  case variant
  when :submitted
    { created_by: user_id }
  when :organized
    { right_plus: [OrganizerID, { refer_to: user_id }] }
  else
    { or:
        created_query(user_id, :submitted).merge(
          created_query(user_id, :organized)
        ) }
  end
end

format :html do
  view :core do
    core_with_listing
  end
end
