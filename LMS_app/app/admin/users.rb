ActiveAdmin.register User do

  # See permitted parameters documentation:
  # https://github.com/activeadmin/activeadmin/blob/master/docs/2-resource-customization.md#setting-up-strong-parameters
  #
  # Uncomment all parameters which should be permitted for assignment
  #
  permit_params :email, :remember_created_at

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