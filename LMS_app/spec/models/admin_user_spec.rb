#

require 'rails_helper'

RSpec.describe AdminUser, type: :model do
  subject(:admin_user) { create(:admin_user) }

  describe '.includes ransackable attributes' do
    it('includes only the specified attributes') do
      expect(AdminUser.ransackable_attributes).to match_array(%w[
                                                                email
                                                                created_at
                                                                updated_at
                                                                id
                                                              ])
    end
  end
end
