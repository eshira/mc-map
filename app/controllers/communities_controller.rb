class CommunitiesController < ApplicationController
  # params:
  #   limit - number of results per page, defaults to 50
  #   page - page of results to get, defaults to 1 (NOT zero-based)
  #   campus - blank, or enum value from Community::CAMPUSES
  #   host_day - blank, or enum value from Community::DAYS
  #   kinds - blank, or comma-seperated list of enum value from
  #           Community::MC_KINDS
  #   points_only - true if only minimal point data is to be returned
  def index
    # pull params from the params hash
    limit = (params[:limit] || 50).to_i
    page = (params[:page] || 1).to_i
    points_only = params[:points_only] == 'true'

    # normalize all filter values to lowercase
    filters = params.slice(:campus, :host_day)
    filters.each do |k, v|
      # Turn into array, split by comma, to do IN query.
      # e.g. where host_day IN ('monday', ...)
      filters[k] = v.downcase.split(",")
    end

    communities = Community.where(filters).with_kinds(params[:kinds]).page(page).per(limit)
    @response = communities.map do |community|
      response = nil

      # return only minimal point data if specified
      if points_only
        point = {
          type: 'Feature',
          geometry: nil,

          # so the user can look up the full data later
          properties: {
            slug: community.slug,
            campus: community.campus,
          },
        }

        # add the coordinates if they're available
        if (community.lat && community.lng)
          point[:geometry] = {
            type: 'Point',
            coordinates: [community.lng.to_f, community.lat.to_f]
          }
        end

        response = point
      else
        response = community.output_json
      end

    end

    respond_to do |format|
      format.json { render :json => @response }
    end
  end

  def signup_form
    @member = Member.new
  end

  def signup
     @community = Community.where(id: params[:community_id]).first

     if @community.blank?
       respond_to do |format|
         format.json { render :json => ApiResponse.fail(community_id: "Must be specified.") }
       end
       return
     end

     email = params[:member].try(:[], :email)
     @member = Member.where(email: email).first

     if @member.blank?
       # Member does not previously exist; create.
       @member = Member.new(params[:member])
       unless @member.save
         respond_to do |format|
           format.json { render :json => ApiResponse.fail(member: @member.errors.as_json) }
         end
         return
       end
     end

     @community.signup!(@member)
     respond_to do |format|
       format.json do
         render :json => ApiResponse.success(member: @member.id, community: @community.id)
       end
     end
  end
end
