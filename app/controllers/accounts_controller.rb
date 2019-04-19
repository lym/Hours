class AccountsController < ApplicationController
  skip_before_action :authenticate_user!, only: [:new, :create]
  before_action :authorize!, only: [:edit, :destroy]

  def new
    @signup = Signup.new
  end

  def create
    @signup = Signup.new(signup_params)
    if @signup.valid?
      Apartment::Tenant.create(@signup.subdomain)
      Apartment::Tenant.switch(@signup.subdomain)
      @signup.save
      redirect_to new_user_session_url(subdomain: @signup.subdomain)
    else
      render action: "new"
    end
  end

  def edit
    @current_domain = request.host
    @user = current_user
  end

  def destroy
    current_account.destroy
    Apartment::Tenant.drop(current_subdomain)
  end

  def update
    @user = current_user
    if @user.respond_to?(:unconfirmed_email)
      prev_unconfirmed_email = @user.unconfirmed_email
    end

    if @user.update_with_password(user_params)
      flash_key = if update_needs_confirmation?(@user, prev_unconfirmed_email)
                    :update_needs_confirmation
                  else
                    :updated
                  end
      redirect_to edit_user_path, notice: t(".#{flash_key}")
    else
      render :edit
    end
  end

  private

  def signup_params
    params.require(:signup)
          .permit(:subdomain, :first_name, :last_name, :email,
                    :password, :password_confirmation)
  end

  def authorize!
    raise ActiveRecord::RecordNotFound unless current_user_owner?
  end
end
