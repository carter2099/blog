class Subscriber < ApplicationRecord
  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }

  before_create { self.token = SecureRandom.urlsafe_base64(32) }

  scope :confirmed, -> { where.not(confirmed_at: nil) }

  def confirmed? = confirmed_at.present?

  def confirm! = update!(confirmed_at: Time.current)
end
