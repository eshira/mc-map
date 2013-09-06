class Admin2::CommunitiesController < Admin2::Admin2Controller
  before_filter :find_community, only: [:show, :edit, :update]

  def index
    @communities = Community.all

    @members_count = CommunitiesMembers.group(:community_id).where(:community_id => @communities).count
    @taggings_hash = {}
    taggings = ActsAsTaggableOn::Tagging.where(:taggable_id => @communities, :taggable_type => Community, :context => "kinds").includes(:tag)
    taggings.each do |tagging|
      @taggings_hash[tagging.taggable_id] ||= []
      @taggings_hash[tagging.taggable_id] << tagging.tag
    end
  end

  def show
  end

  def edit
  end

  def update
    respond_to do |format|
      if @community.update_attributes(params[:community])
        format.html { redirect_to admin2_community_path(@community), notice: "Community was successfully updated." }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @community.errors, status: :unprocessable_entity }
      end
    end
  end

  def add_coach
    @community = Community.find(params[:id])
    admin_user = AdminUser.find(params[:admin_user_id])
    @community.coaches << admin_user
    redirect_to :back
  end

  def remove_coach
    @community = Community.find(params[:id])
    admin_user = AdminUser.find(params[:admin_user_id])
    @community.coaches.destroy(admin_user)
    redirect_to :back
  end

  private

  def find_community
    @community = Community.find(params[:id])
  end
end
