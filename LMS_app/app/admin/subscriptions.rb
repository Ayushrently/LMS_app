# frozen_string_literal: true

ActiveAdmin.register Subscription do
  # See permitted parameters documentation:
  # https://github.com/activeadmin/activeadmin/blob/master/docs/2-resource-customization.md#setting-up-strong-parameters
  #
  # Uncomment all parameters which should be permitted for assignment

  preserve_default_filters!

  permit_params :plan_name, :profile_id

  #
  # or
  #
  # permit_params do
  #   permitted = [:plan_name, :profile_id]
  #   permitted << :other if params[:action] == 'create' && current_user.admin?
  #   permitted
  # end

  actions :all, except: %i[new destroy create]

  filter :profile_username, as: :string, label: 'Username'

  batch_action :change_to_pro, confirm: 'Change selected subscriptions to Pro?' do |ids|
    Subscription.where(id: ids).update_all(plan_name: :pro)
    redirect_to collection_path, notice: 'Selected subscriptions have been changed to Pro.'
  end

  batch_action :change_to_basic, confirm: 'Change selected subscriptions to Basic?' do |ids|
    Subscription.where(id: ids).update_all(plan_name: :basic)
    redirect_to collection_path, notice: 'Selected subscriptions have been changed to Basic.'
  end

  index do
    selectable_column
    id_column
    column :plan_name
    column 'Username', sortable: 'profiles.username' do |subscription|
      subscription.profile&.username
    end
    column :created_at
    actions
  end

  form do |f|
    f.inputs 'Subscription Details' do
      f.label :profile, "Username : #{f.object.profile&.username}", style: 'padding-left: 10px'
      f.input :plan_name, as: :select, collection: Subscription.plan_names.keys
    end
    f.actions
  end

  remove_filter :profile
end
