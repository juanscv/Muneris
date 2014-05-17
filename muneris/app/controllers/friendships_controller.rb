class FriendshipsController < ApplicationController
    
  before_filter :authenticate_user!

  def index
    if params[:user_id].nil? then
      @user = current_user
    else
      @user = User.find(params[:user_id])
    end

    @friends_grid = initialize_grid(
      User.unscoped.joins('INNER JOIN friendships ON (friendships.friend_id = users.id OR friendships.friendable_id = users.id)').where('users.id not IN (?) AND (friendships.friendable_id= ? OR friendships.friend_id = ?) AND friendships.pending = 0 AND friendships.blocker_id IS NULL', current_user.id, current_user.id, current_user.id),
      order: 'users.id',
      with_resultset: :process_records,
      per_page: 8,
      name: 'g'
     )

    @results = []

    if params[:g] && params[:g][:selected]
      @selected = params[:g][:selected]
    end

  end

  def new
    if params[:user_id].nil? then
      @user = current_user
    else
      @user = User.find(params[:user_id])
    end

    @users_grid = initialize_grid(
      User,
      conditions: ["id != ?", current_user.id],
      order: 'users.id',
      per_page: 8
    )
    
  end

  def create
    invitee = User.find_by_id(params[:user_id])
    if current_user.invite invitee
      redirect_to new_network_path, :notice => "Successfully invited friend!"
    else
      redirect_to new_network_path, :notice => "Sorry! You can't invite that user!"
    end
    if params[:user_id].nil? then
      @user = current_user
    else
      @user = User.find(params[:user_id])
    end
  end

  def update
    inviter = User.find_by_id(params[:id])
    if current_user.approve inviter
      redirect_to new_network_path, :notice => "Successfully confirmed friend!"
    else
      redirect_to new_network_path, :notice => "Sorry! Could not confirm friend!"
    end
    if params[:user_id].nil? then
      @user = current_user
    else
      @user = User.find(params[:user_id])
    end
  end

  def requests
    @pending_requests = current_user.pending_invited_by
    if params[:user_id].nil? then
      @user = current_user
    else
      @user = User.find(params[:user_id])
    end
  end

  def invites
    @pending_invites = current_user.pending_invited
    if params[:user_id].nil? then
      @user = current_user
    else
      @user = User.find(params[:user_id])
    end
  end

  def destroy
    user = User.find_by_id(params[:id])
    if current_user.remove_friendship user
      redirect_to new_network_path, :notice => "Successfully removed friend!"
    else
      redirect_to new_etwork_path, :notice => "Sorry, couldn't remove friend!"
    end
    if params[:user_id].nil? then
      @user = current_user
    else
      @user = User.find(params[:user_id])
    end
  end

  def process_records(records)
    @results = records.find(:all)
  end
  
end
