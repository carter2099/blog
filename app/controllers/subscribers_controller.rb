class SubscribersController < ApplicationController
  allow_unauthenticated_access

  def new
  end

  def create
    email = params[:email]&.strip&.downcase
    subscriber = Subscriber.find_by(email: email)

    if subscriber&.confirmed?
      redirect_to new_subscriber_path, notice: "You're already subscribed!"
      return
    end

    subscriber ||= Subscriber.new(email: email)

    if subscriber.save
      SubscriberMailer.with(subscriber: subscriber).confirmation.deliver_later
      redirect_to new_subscriber_path, notice: "Check your email to confirm your subscription."
    else
      flash.now.alert = subscriber.errors.full_messages.join(", ")
      render :new, status: :unprocessable_entity
    end
  end

  def confirm
    subscriber = Subscriber.find_by!(token: params[:token])
    subscriber.confirm!
    render :confirm
  rescue ActiveRecord::RecordNotFound
    redirect_to new_subscriber_path, alert: "Invalid confirmation link."
  end

  def unsubscribe
    subscriber = Subscriber.find_by!(token: params[:token])
    subscriber.destroy
    render :unsubscribe
  rescue ActiveRecord::RecordNotFound
    redirect_to new_subscriber_path, alert: "Invalid unsubscribe link."
  end
end
