ActiveAdmin.register Profile do
  # See permitted parameters documentation:
  # https://github.com/activeadmin/activeadmin/blob/master/docs/2-resource-customization.md#setting-up-strong-parameters
  #
  # Uncomment all parameters which should be permitted for assignment
  #
  preserve_default_filters!

  permit_params :name, :bio, :username, :user_id,
                subscription_attributes: %i[id plan_name]

  filter :subscription_plan_name,
         as: :select,
         collection: %w[pro basic],
         label: 'Membership Plan'

  remove_filter :subscription, :user

  batch_action :change_to_pro, confirm: 'Change selected profiles to Pro?' do |ids|
    Profile.where(id: ids).each do |profile|
      profile.subscription&.update(plan_name: :pro)
    end
    redirect_to collection_path, notice: 'Selected profiles have been changed to Pro.'
  end

  batch_action :change_to_basic, confirm: 'Change selected profiles to Basic?' do |ids|
    Profile.where(id: ids).each do |profile|
      profile.subscription&.update(plan_name: :basic)
    end
    redirect_to collection_path, notice: 'Selected profiles have been changed to Basic.'
  end

  form do |f|
    f.inputs "Profile Details" do
      f.input :user, as: :select, collection: User.all.map { |u| [u.email, u.id] }
      f.input :name
      f.input :username
      f.input :bio, required: true
      f.semantic_fields_for :subscription do |s|
        s.input :plan_name,
                as: :select,
                collection: Subscription.plan_names.keys,
                selected: s.object.plan_name || 'free'
      end
    end
    f.actions
  end
end
