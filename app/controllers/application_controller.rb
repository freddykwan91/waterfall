class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  before_action :authenticate_user!
  helper_method :show_export?

  # this is additional code to allow only admin to admin section of the website
  # before_action :authenticate_admin!, if: :rails_admin_url

  # this is additional code to include first and last names in sign up and user models
  before_action :configure_permitted_parameters, if: :devise_controller?

  # if user is logged in, return current_user, else return guest_user
  def current_or_guest_user
    if current_user
      if session[:guest_user_id] && session[:guest_user_id] != current_user.id
        logging_in
        # reload guest_user to prevent caching problems before destruction
        guest_user(with_retry = false).try(:reload).try(:destroy)
        session[:guest_user_id] = nil
      end
      current_user
    else
      guest_user
    end
  end

  def show_export?
    ((params[:action] == 'edit') && (controller_name == "charts"))
  end

  # find guest_user object associated with the current session,
  # creating one as needed
  def guest_user(with_retry = true)
    # Cache the value the first time it's gotten.
    @cached_guest_user ||= User.find(session[:guest_user_id] ||= create_guest_user.id)

    rescue ActiveRecord::RecordNotFound # if session[:guest_user_id] invalid
     session[:guest_user_id] = nil
     guest_user if with_retry
  end

  def configure_permitted_parameters
    # For additional fields in app/views/devise/registrations/new.html.erb
    devise_parameter_sanitizer.permit(:sign_up, keys: [:first_name, :last_name])

    # For additional in app/views/devise/registrations/edit.html.erb
    devise_parameter_sanitizer.permit(:account_update, keys: [:username])
  end

  def authenticate_admin!
    unless current_user.admin
      flash[:alert] = "You do not have the rights to access the admin panel"
      redirect_to root_path
    end
  end

  # This is a custom method to toggle show/hide of export button in navbar
  def show_export?
    ((params[:action] == 'edit') && (controller_name == "charts"))
  end

  private

  # called (once) when the user logs in, insert any code your application needs
  # to hand off from guest_user to current_user.
  def logging_in
    guest_charts = guest_user.charts
    guest_charts.each do |chart|
      chart.user_id = current_user.id
      chart.save
    end
    # For example:
    # guest_comments = guest_user.comments.all
    # guest_comments.each do |comment|
      # comment.user_id = current_user.id
      # comment.save!
    # end
  end

  def create_guest_user
    u = User.new(first_name: "guest", last_name: "a", email: "guest_#{Time.now.to_i}#{rand(100)}@example.com")
    u.save!(:validate => false)
    session[:guest_user_id] = u.id
    u
  end

  def default_url_options
    { host: ENV["HOST"] || "localhost:3000" }
  end
end
