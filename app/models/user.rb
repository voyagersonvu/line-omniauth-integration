class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :omniauthable, omniauth_providers: [ :line ]

  # This class method handles user creation or lookup via OmniAuth authentication (in this case, LINE).
  def self.from_omniauth(auth)
    # Try to find an existing user by the provider and UID
    user = find_by(provider: auth.provider, uid: auth.uid)

    unless user
      # If no user is found, create a new user.

      # Check if the LINE authentication provides an email. If not, create a placeholder email.
      email = auth.info.email.presence || "line_user_#{auth.uid}@example.com"

      # If the email already exists for another user, generate a new email by adding a random number.
      while exists?(email: email)
        email = "line_user_#{auth.uid}_#{rand(1000)}@example.com"
      end

      # Create a new user object using the data from the OmniAuth response.
      user = new(
        provider: auth.provider,
        uid: auth.uid,
        email: email,
        name: auth.info.name || "LineUser#{auth.uid}",
        image: auth.info.image,
        password: Devise.friendly_token[0, 20]
      )

      user.save!
    end

    user
  end
end
