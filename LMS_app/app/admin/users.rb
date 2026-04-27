ActiveAdmin.register User do

  # See permitted parameters documentation:
  # https://github.com/activeadmin/activeadmin/blob/master/docs/2-resource-customization.md#setting-up-strong-parameters
  #
  # Uncomment all parameters which should be permitted for assignment
  #
  # Prevent accidental user deletion from admin — users have cascading dependents
  actions :all, except: [:destroy]

  permit_params :email, :password, :password_confirmation, :role

  form do |f|
    f.inputs "User Details" do
      f.input :email
      f.input :password
      f.input :password_confirmation
    end
    f.actions
  end

  controller do
    def update
      if params[:user][:password].blank?
        params[:user].delete(:password)
        params[:user].delete(:password_confirmation)
      end
      super
    end
  end

    index do
      column :id
      column :email
      column :created_at
      column :updated_at
      actions
    end

    show do
      attributes_table do
        row :id
        row :email
        row :created_at
        row :updated_at
      end
    end

  #
  # or
  #
  # permit_params do
  #   permitted = [:email, :encrypted_password, :reset_password_token, :reset_password_sent_at, :remember_created_at, :role]
  #   permitted << :other if params[:action] == 'create' && current_user.admin?
  #   permitted
  # end
  filter :email
  filter :created_at
  filter :updated_at
end