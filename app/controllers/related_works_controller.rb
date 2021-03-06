class RelatedWorksController < ApplicationController

  before_filter :users_only, :except => [:index]
  before_filter :get_instance_variables, :except => [:index]

  def index
    if params[:user_id].blank?
      setflash; flash[:error] = ts("Whose related works were you looking for?")
      redirect_back_or_default(people_path)
    else
      @user = User.find_by_login(params[:user_id])
      if @user.blank?
        setflash; flash[:error] = ts("Sorry, we couldn't find that user")
        redirect_back_or_default(root_path)
      else
        @translations_of_user = @user.related_works.find(:all, :conditions => {:translation => true})
        @remixes_of_user = @user.related_works.find(:all, :conditions => {:translation => false})
        @translations_by_user = @user.parent_work_relationships.find(:all, :conditions => {:translation => true})
        @remixes_by_user = @user.parent_work_relationships.find(:all, :conditions => {:translation => false})
      end
    end
  end

  # GET /related_works/1
  # GET /related_works/1.xml
  def show
  end

  def update
    # updates are done by the owner of the parent, to aprove or remove links on the parent work.
    unless @user
      if current_user_owns?(@child)
        setflash; flash[:error] = ts("Sorry, but you don't have permission to do that. Try removing the link from your own work.")
        redirect_back_or_default(user_related_works_path(current_user))
        return
      else
        setflash; flash[:error] = ts("Sorry, but you don't have permission to do that.")
        redirect_back_or_default(root_path)
        return
      end
    end
    # the assumption here is that any update is a toggle from what was before
    @related_work.reciprocal = !@related_work.reciprocal?
    if @related_work.update_attribute(:reciprocal, @related_work.reciprocal)
      notice = @related_work.reciprocal? ?  ts("Link was successfully approved") :
                                            ts("Link was successfully removed")
      setflash; flash[:notice] = notice
      redirect_to(@related_work.parent)
    else
      setflash; flash[:error] = ts('Sorry, something went wrong.')
      redirect_to(@related_work)
    end
  end

  def destroy
    # destroys are done by the owner of the child, to remove links to the parent work which also removes the link back if it exists.
    unless current_user_owns?(@child)
      if @user
        setflash; flash[:error] = ts("Sorry, but you don't have permission to do that. You can only approve or remove the link from your own work.")
        redirect_back_or_default(user_related_works_path(current_user))
        return
      else
        setflash; flash[:error] = ts("Sorry, but you don't have permission to do that.")
        redirect_back_or_default(root_path)
        return
      end
    end
    @related_work.destroy
    redirect_back_or_default(user_related_works_path(current_user))
  end

  private

  def get_instance_variables
    @related_work = RelatedWork.find(params[:id])
    @child = @related_work.work
    if @related_work.parent.is_a? (Work)
      @owners = @related_work.parent.pseuds.map(&:user)
      @user = current_user if @owners.include?(current_user)
    end
  end

end
