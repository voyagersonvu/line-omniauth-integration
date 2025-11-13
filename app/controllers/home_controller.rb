class HomeController < ApplicationController
  def index; end

  def privacy;end

  def terms;end

  def send_line_notification
    if current_user.uid.present?
      User.all.each do |user|
        LineNotifyService.new(user).send_message("hello world Viet - Tri ")
      end

      flash[:notice] = "Notification sent to LINE!"
    else
      flash[:alert] = "LINE ID not found. Can't send notification."
    end

    redirect_to root_path
  end
end
