module Backend::AffairsHelper

  def affair_of(deal)
    render partial: "backend/affairs/show", object: deal.affair, locals: {affair: deal.affair, current_deal: deal}
  end

end
